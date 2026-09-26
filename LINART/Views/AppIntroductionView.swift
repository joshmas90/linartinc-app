import SwiftUI

/// Once per app launch; returning from the background or navigating never replays.
struct AppIntroductionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var openingIntroduction = true

    private var isIntroductionPresented: Bool {
        openingIntroduction || store.introductionReplayRequested
    }

    var body: some View {
        ZStack {
            RootView()
                .opacity(isIntroductionPresented ? 0 : 1)
                .allowsHitTesting(!isIntroductionPresented)
                .accessibilityHidden(isIntroductionPresented)

            if isIntroductionPresented {
                BrandIntroductionView(onFinish: finishIntroduction)
                    .transition(reduceMotion ? .identity : .opacity)
                    .zIndex(1)
            }
        }.background(Brand.cream.ignoresSafeArea())
    }

    private func finishIntroduction() {
        guard isIntroductionPresented else { return }
        // The current screen stays mounted underneath, preserving navigation/drafts.
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
            openingIntroduction = false
            store.introductionReplayRequested = false
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
        scenePhase == .active &&
        !requiresManualDismissal &&
        !ProcessInfo.processInfo.arguments.contains("-LINARTDisableWelcomeAutoDismiss")
    }

    private var motionEnabled: Bool {
        !reduceMotion && !requiresManualDismissal
    }

    private var contentVisible: Bool {
        revealed || !motionEnabled
    }

    private func motion(_ animation: Animation) -> Animation? {
        motionEnabled ? animation : nil
    }

    var body: some View {
        GeometryReader { bounds in
            // Keep the complete square artwork, with room for the native copy
            // on smaller phones and restrained margins on larger displays.
            let portraitPhotoSide = max(0, min(bounds.size.width - 48,
                max(180, min(560, min(bounds.size.height * 0.48, bounds.size.height - 350)))))
            let landscapePhotoSide = max(0, min(560,
                min(bounds.size.width * 0.54 - 24, bounds.size.height - 24)))
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
                        .frame(width: landscapePhotoSide, height: landscapePhotoSide)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        wordmark
                        photograph
                            .frame(width: portraitPhotoSide, height: portraitPhotoSide)
                            .frame(maxWidth: .infinity)
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
        .transaction { transaction in
            if !motionEnabled {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .task {
            // A single state change coordinates each element's local timing.
            // Even without motion, retain the settled state if settings change.
            revealed = true
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
            wordmarkLetters
                .foregroundStyle(Brand.ink)
                .overlay {
                    if motionEnabled {
                        wordmarkLightSweep
                    }
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 5)
                .animation(motion(.easeOut(duration: 0.55)), value: revealed)
                .accessibilityAddTraits(.isHeader)
            Text("CRAFTED AROUND YOU")
                .font(.caption.weight(.medium))
                .tracking(2.4)
                .foregroundStyle(Brand.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 4)
                .animation(motion(.easeOut(duration: 0.55).delay(0.18)), value: revealed)
            brassRule
                .scaleEffect(x: contentVisible ? 1 : 0, y: 1)
                .animation(motion(.easeInOut(duration: 0.45).delay(0.28)), value: revealed)
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var wordmarkLetters: some View {
        Text("LINART")
            .font(.system(size: wordmarkSize, weight: .regular, design: .serif))
            .tracking(6)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var wordmarkLightSweep: some View {
        GeometryReader { bounds in
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Brand.brass.opacity(0.75), location: 0.36),
                .init(color: Brand.gold, location: 0.5),
                .init(color: Brand.brass.opacity(0.75), location: 0.64),
                .init(color: .clear, location: 1)
            ], startPoint: .leading, endPoint: .trailing)
            .frame(width: bounds.size.width * 0.65, height: bounds.size.height * 2)
            .rotationEffect(.degrees(12))
            .offset(x: revealed ? bounds.size.width * 1.2 : -bounds.size.width * 0.9,
                    y: -bounds.size.height * 0.5)
            .animation(.easeInOut(duration: 1.05).delay(0.9), value: revealed)
        }
        .mask(wordmarkLetters)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var photograph: some View {
        GeometryReader { bounds in
            Image("welcome-bathroom")
                .resizable()
                .scaledToFill()
                .frame(width: bounds.size.width, height: bounds.size.height)
                .scaleEffect(motionEnabled ? (revealed ? 1 : 1.055) : 1)
                .animation(motion(.timingCurve(0.16, 1, 0.3, 1, duration: 1.95).delay(0.25)), value: revealed)
                .blur(radius: contentVisible ? 0 : 3)
                .opacity(contentVisible ? 1 : 0.35)
                .animation(motion(.easeOut(duration: 1).delay(0.25)), value: revealed)
                .clipped()
                .mask(alignment: .top) {
                    // An oversized alpha gradient moves down through the frame.
                    // Its broad feather has no hard leading edge, and the final
                    // viewport sits entirely inside the opaque portion.
                    LinearGradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.48),
                        .init(color: .white.opacity(0.95), location: 0.56),
                        .init(color: .white.opacity(0.65), location: 0.65),
                        .init(color: .white.opacity(0.25), location: 0.73),
                        .init(color: .clear, location: 0.82),
                        .init(color: .clear, location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                    .frame(height: bounds.size.height * 2.2)
                    .offset(y: contentVisible ? 0 : -bounds.size.height * 2.2)
                    .animation(motion(.easeInOut(duration: 1.20).delay(0.25)), value: revealed)
                }
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
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 7)
                .animation(motion(.easeOut(duration: 0.55).delay(1.45)), value: revealed)
            Text("NEW JERSEY")
                .font(.caption.weight(.medium))
                .tracking(3)
                .foregroundStyle(Brand.secondary)
                .opacity(contentVisible ? 1 : 0)
                .animation(motion(.easeOut(duration: 0.45).delay(1.70)), value: revealed)
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
            .accessibilityLabel("Continue to LINART")
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
