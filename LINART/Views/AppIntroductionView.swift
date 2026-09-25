import SwiftUI

/// Kept outside the tab hierarchy so navigation never replays the introduction.
struct AppIntroductionView: View {
    @AppStorage("linart.hasSeenBrandIntroduction") private var hasSeenIntroduction = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RootView()
                .allowsHitTesting(hasSeenIntroduction)
                .accessibilityHidden(!hasSeenIntroduction)

            if !hasSeenIntroduction {
                BrandIntroductionView(onFinish: finishIntroduction)
                    .transition(reduceMotion ? .identity : .opacity)
                    .zIndex(1)
            }
        }
    }

    private func finishIntroduction() {
        guard !hasSeenIntroduction else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.4)) {
            hasSeenIntroduction = true
        }
    }
}

private struct BrandIntroductionView: View {
    let onFinish: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkSize: CGFloat = 56
    @ScaledMetric(relativeTo: .title) private var headlineSize: CGFloat = 32
    @State private var revealed = false

    private let ivory = Color(red: 245 / 255, green: 240 / 255, blue: 231 / 255)

    // Leave reading time in the user's control with VoiceOver or accessibility text.
    private var requiresManualDismissal: Bool {
        voiceOverEnabled || dynamicTypeSize.isAccessibilitySize
    }

    private var shouldAutoDismiss: Bool {
        scenePhase == .active && !requiresManualDismissal
    }

    var body: some View {
        GeometryReader { bounds in
            if bounds.size.width > bounds.size.height && bounds.size.width > 600
                && !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            wordmark
                            message
                        }
                        .frame(maxWidth: .infinity, minHeight: bounds.size.height)
                    }
                    .frame(width: bounds.size.width * 0.46)
                    photograph
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        wordmark
                        photograph
                            .frame(height: max(180, min(560, bounds.size.height * 0.48)))
                        message
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: bounds.size.height)
                }
            }
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .background(ivory.ignoresSafeArea())
        .accessibilityIdentifier("brandIntroduction")
        .task {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.8)) {
                revealed = true
            }
        }
        .task(id: shouldAutoDismiss) {
            guard shouldAutoDismiss else { return }
            do {
                try await Task.sleep(for: .seconds(3))
            } catch {
                return
            }
            guard !Task.isCancelled, shouldAutoDismiss else { return }
            onFinish()
        }
    }

    private var wordmark: some View {
        VStack(spacing: 14) {
            Text("LINART")
                .font(.system(size: wordmarkSize, weight: .regular, design: .serif))
                .tracking(6)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Brand.ink)
                .accessibilityAddTraits(.isHeader)
            Text("CRAFTED AROUND YOU")
                .font(.caption.weight(.medium))
                .tracking(2.4)
                .foregroundStyle(Brand.secondary)
                .fixedSize(horizontal: false, vertical: true)
            brassRule
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .opacity(revealed || reduceMotion ? 1 : 0)
        .accessibilityElement(children: .combine)
    }

    private var photograph: some View {
        GeometryReader { bounds in
            Image("kitchen-remodeling")
                .resizable()
                .scaledToFill()
                .frame(width: bounds.size.width, height: bounds.size.height)
                .scaleEffect(revealed || reduceMotion ? 1 : 1.025)
                .opacity(revealed || reduceMotion ? 1 : 0.7)
                .clipped()
        }
        .accessibilityHidden(true)
    }

    private var message: some View {
        VStack(spacing: 16) {
            Text("Your home.\nBeautifully reimagined.")
                .font(.system(size: headlineSize, weight: .regular, design: .serif))
                .tracking(-0.5)
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("NEW JERSEY")
                .font(.caption.weight(.medium))
                .tracking(3)
                .foregroundStyle(Brand.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        HStack {
            brassRule
            Spacer(minLength: 16)
            Button(action: onFinish) {
                Text(requiresManualDismissal ? "Continue" : "Skip")
                    .font(.subheadline)
                    .foregroundStyle(Brand.bronze)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 60, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Continue to LINART home")
            .accessibilityIdentifier("skipBrandIntroduction")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
        .background(ivory)
    }

    private var brassRule: some View {
        Rectangle()
            .fill(Brand.brass)
            .frame(width: 36, height: 1)
            .accessibilityHidden(true)
    }
}
