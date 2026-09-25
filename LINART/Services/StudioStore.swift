import Foundation
import Combine
import PhotosUI
import SwiftUI

@MainActor
final class StudioStore: ObservableObject {
    enum State: Equatable { case loading, ready, unavailable(String), clearing }
    @Published var draft = StudioDraft() { didSet { if !suppressChanges && draft != oldValue { changed() } } }
    @Published private(set) var state: State = .loading
    @Published private(set) var savedAt: Date?
    @Published private(set) var isSaving = false
    @Published private(set) var hasUnsavedChanges = false
    @Published private(set) var isImporting = false
    @Published private(set) var isExporting = false
    @Published var notice: String?
    @Published var exportError: String?
    @Published var shareURL: URL?
    @Published var lastExportedAt: Date?
    let persistence: StudioPersistence
    private var generation = 0
    private var revision = 0
    private var suppressChanges = false
    private var saveTask: Task<Void, Never>?
    private var importTask: Task<Void, Never>?
    private var exportTask: Task<Void, Never>?

    init(persistence: StudioPersistence = StudioPersistence()) { self.persistence = persistence }
    var isReady: Bool { state == .ready }
    var saveLabel: String {
        if isSaving { return "Saving on this device…" }
        if hasUnsavedChanges { return "Changes not saved · try Save now" }
        if let savedAt { return "Saved on this device · \(savedAt.formatted(date: .omitted, time: .shortened))" }
        return "Private on this device"
    }

    func load() async {
        guard !isReady, state != .clearing else { return }
        let token = generation
        state = .loading
        do {
            let envelope = try await persistence.load()
            guard token == generation else { return }
            suppressChanges = true
            draft = envelope?.draft ?? StudioDraft()
            suppressChanges = false
            savedAt = envelope?.savedAt == .distantPast ? nil : envelope?.savedAt
            state = .ready
            do { try await persistence.cleanExpiredExports() }
            catch { Diagnostics.shared.record(.exportCleanupFailed) }
        } catch { guard token == generation else { return }; state = .unavailable(error.localizedDescription); Diagnostics.shared.record(.draftLoadFailed) }
    }

    private func changed() {
        guard isReady else { return }
        revision += 1
        hasUnsavedChanges = true
        isSaving = true
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
            await self?.persistCurrent()
        }
    }

    func flush() async {
        saveTask?.cancel()
        guard isReady, hasUnsavedChanges else { return }
        await persistCurrent()
    }

    private func persistCurrent() async {
        let token = generation, currentRevision = revision, snapshot = draft
        do {
            let date = try await persistence.save(snapshot, generation: token, revision: currentRevision)
            guard token == generation, currentRevision == revision else { return }
            savedAt = date; isSaving = false; hasUnsavedChanges = false
        } catch StudioStorageError.staleOperation { }
        catch {
            guard token == generation else { return }
            isSaving = false
            notice = "Your latest changes have not been saved. \(error.localizedDescription)"
            Diagnostics.shared.record(.draftSaveFailed)
        }
    }

    func recover() async {
        let token = generation
        guard state != .clearing else { return }
        do {
            let envelope = try await persistence.recoverPrevious()
            guard token == generation else { return }
            suppressChanges = true; draft = envelope.draft; suppressChanges = false
            savedAt = envelope.savedAt; state = .ready; notice = "Recovered the previous saved copy. The unreadable file was preserved."
        } catch { guard token == generation else { return }; state = .unavailable("Recovery was not possible. Your original files are still intact. \(error.localizedDescription)") }
    }

    func clear() async throws {
        guard state != .clearing else { return }
        let previousState = state
        state = .clearing
        generation += 1
        saveTask?.cancel(); importTask?.cancel(); exportTask?.cancel()
        isSaving = false; isImporting = false; isExporting = false
        do {
            try await persistence.reset(to: generation)
            suppressChanges = true; draft = StudioDraft(); suppressChanges = false
            revision = 0; savedAt = nil; hasUnsavedChanges = false; lastExportedAt = nil; shareURL = nil; exportError = nil
            notice = "Your local Studio and prepared exports were removed."
            state = .ready
        } catch {
            state = previousState
            notice = "Some files could not be removed. Please try again."
            Diagnostics.shared.record(.resetFailed)
            throw error
        }
    }

    func importPhotos(_ selections: [PhotosPickerItem], purpose: String) {
        guard isReady, !isImporting, !selections.isEmpty else { return }
        let token = generation
        let selected = Array(selections.prefix(max(0, 8 - draft.photos.count)))
        isImporting = true; notice = nil
        importTask = Task { [weak self] in
            guard let self else { return }
            var added = 0, failed = 0
            for item in selected {
                do {
                    try Task.checkCancellation()
                    guard let data = try await item.loadTransferable(type: Data.self) else { throw StudioImageError.invalidImage }
                    guard token == generation, !Task.isCancelled else { return }
                    let image = try await Task.detached(priority: .userInitiated) { try StudioImageProcessor.normalize(data) }.value
                    guard token == generation, !Task.isCancelled else { return }
                    let photo = try await persistence.addPhoto(image, purpose: purpose, generation: token)
                    guard token == generation, !Task.isCancelled else { return }
                    draft.photos.append(photo); added += 1
                } catch is CancellationError { return }
                catch StudioStorageError.staleOperation { return }
                catch { failed += 1; Diagnostics.shared.record(.photoImportFailed) }
            }
            guard token == generation else { return }
            isImporting = false
            notice = "\(added) photo\(added == 1 ? "" : "s") added." + (failed > 0 ? " \(failed) could not be added. Choose standard images under 25 MB and try again." : " Saved privately on this device.")
            await flush()
        }
    }

    func removePhoto(_ photo: StudioPhoto) async {
        let token = generation
        do {
            try await persistence.removePhoto(photo, generation: token)
            guard token == generation else { return }
            draft.photos.removeAll { $0.id == photo.id }
            await flush()
        } catch { notice = "This photo could not be fully removed. Try again."; Diagnostics.shared.record(.photoRemovalFailed) }
    }

    func export(mode: StudioExportMode) {
        guard isReady, !isExporting, !isImporting else { return }
        let token = generation, snapshot = draft
        isExporting = true; exportError = nil
        exportTask = Task { [weak self] in
            guard let self else { return }
            await flush()
            do {
                let url = try await persistence.export(snapshot, mode: mode, generation: token)
                guard token == generation, !Task.isCancelled else { try? await persistence.removeExport(url); return }
                shareURL = url; lastExportedAt = Date(); isExporting = false
            } catch {
                guard token == generation else { return }
                isExporting = false; exportError = error.localizedDescription
                Diagnostics.shared.record(.pdfExportFailed)
            }
        }
    }

    func finishSharing(_ url: URL) {
        shareURL = nil
        Task {
            do { try await persistence.removeExport(url) }
            catch { notice = "A prepared export could not be removed. Clear local data to retry cleanup."; Diagnostics.shared.record(.exportCleanupFailed) }
        }
    }

    func include(_ project: PortfolioProject) {
        guard isReady, !draft.ideas.contains(where: { $0.id == project.id }) else { return }
        draft.ideas.append(StudioIdea(id: project.id, title: project.title))
    }
}
