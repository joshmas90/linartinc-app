import SwiftUI

enum Brand {
    static let ink = Color(red: 11 / 255, green: 13 / 255, blue: 16 / 255)
    static let cream = Color(red: 249 / 255, green: 248 / 255, blue: 245 / 255)
    static let paper = Color(red: 255 / 255, green: 254 / 255, blue: 251 / 255)
    static let gold = Color(red: 215 / 255, green: 193 / 255, blue: 154 / 255)
    static let secondary = Color(red: 91 / 255, green: 89 / 255, blue: 84 / 255)
    static let line = Color(red: 226 / 255, green: 220 / 255, blue: 210 / 255)
    static let brass = Color(red: 145 / 255, green: 105 / 255, blue: 43 / 255)
    static let bronze = Color(red: 115 / 255, green: 80 / 255, blue: 36 / 255)
}

enum PremiumLayout {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let xl: CGFloat = 40
    // iOS 26's floating tab bar intentionally overlays content; keep the final
    // planner controls comfortably above it rather than merely visible through it.
    static let tabBarClearance: CGFloat = 104
}

struct BrandWordmark: View {
    var light = false

    var body: some View {
        VStack(spacing: 7) {
            Text("LINART")
                .font(.system(.largeTitle, design: .serif)).tracking(5)
            Text("BUILD · RENOVATE · IMPROVE")
                .font(.caption2.weight(.medium)).tracking(1.8)
        }
        .foregroundStyle(light ? .white : Brand.ink)
        .accessibilityElement(children: .combine)
    }
}

struct Eyebrow: View {
    let title: String
    var light = false

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold)).tracking(1.7)
            .foregroundStyle(light ? Brand.gold : Brand.bronze)
    }
}

struct SectionHeading: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(title: eyebrow)
            Text(title).font(.system(.largeTitle, design: .serif)).foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var light = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.horizontal, 20).padding(.vertical, 15)
            .foregroundStyle(isEnabled ? Color.white : Brand.secondary.opacity(0.72))
            .background(
                isEnabled ? (light ? Brand.paper.opacity(0.14) : Brand.ink) : Brand.line.opacity(0.62),
                in: RoundedRectangle(cornerRadius: 11)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(isEnabled ? (light ? Brand.gold.opacity(0.55) : Brand.brass.opacity(0.48)) : Brand.line)
            )
            .shadow(color: isEnabled ? .black.opacity(configuration.isPressed ? 0.03 : 0.08) : .clear, radius: 10, y: 5)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.992 : 1)
            .opacity(configuration.isPressed && isEnabled ? 0.88 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.16), value: isEnabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.horizontal, 20).padding(.vertical, 14)
            .foregroundStyle(isEnabled ? Brand.ink : Brand.secondary.opacity(0.65))
            .background(configuration.isPressed && isEnabled ? Brand.gold.opacity(0.12) : Brand.paper, in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(isEnabled ? Brand.line : Brand.line.opacity(0.65)))
            .opacity(configuration.isPressed && isEnabled ? 0.78 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.14), value: isEnabled)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isEnabled ? Brand.bronze : Brand.secondary.opacity(0.6))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed && isEnabled ? 0.58 : 1)
    }
}

struct MenuRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    @ScaledMetric(relativeTo: .title2) private var symbolWidth: CGFloat = 30

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Brand.bronze)
                .frame(width: symbolWidth).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(Brand.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Brand.bronze)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(16)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.line))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PortfolioImage: View {
    let photo: ProjectPhoto
    var height: CGFloat = 250

    var body: some View {
        Color.clear
            .frame(height: height)
            .overlay {
                Image(photo.asset).resizable().scaledToFill()
            }
            .clipped()
            .accessibilityLabel(photo.caption)
            .accessibilityAddTraits(.isImage)
    }
}

struct ProjectCard: View {
    let project: PortfolioProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer(minLength: 72)
            Text(project.title).font(.system(.title2, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text("\(project.photos.count) photos · \(project.location)").font(.caption)
                Spacer(minLength: 4)
                Image(systemName: "arrow.right").accessibilityHidden(true)
            }.foregroundStyle(.white.opacity(0.9))
        }
        .foregroundStyle(.white).padding(20)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .bottomLeading)
        .background {
            GeometryReader { bounds in
                if let photo = project.photos.first {
                    Image(photo.asset).resizable().scaledToFill()
                        .frame(width: bounds.size.width, height: bounds.size.height)
                        .clipped().accessibilityHidden(true)
                }
                LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .center, endPoint: .bottom)
            }
        }
        .background(Brand.ink)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.12)))
        .shadow(color: .black.opacity(0.07), radius: 12, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

struct ContactActions: View {
    @Environment(\.openURL) private var openURL
    @State private var unavailable: String?

    var body: some View {
        VStack(spacing: PremiumLayout.sm) {
            Button {
                openURL(Company.phoneURL) { accepted in
                    if !accepted { unavailable = "Call LINART at \(Company.phone) from a phone." }
                }
            } label: {
                ContactActionRow(eyebrow: "Call", title: Company.phone, symbol: "phone")
            }
            Button {
                openURL(Company.emailURL) { accepted in
                    if !accepted { unavailable = "Email \(Company.email) using your preferred email app." }
                }
            } label: {
                ContactActionRow(eyebrow: "Email", title: Company.email, symbol: "envelope")
            }
        }
        .buttonStyle(.plain)
        .alert("Contact LINART", isPresented: Binding(
            get: { unavailable != nil }, set: { if !$0 { unavailable = nil } }
        )) {
            Button("OK", role: .cancel) { unavailable = nil }
        } message: { Text(unavailable ?? "") }
    }
}

private struct ContactActionRow: View {
    let eyebrow: String
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: PremiumLayout.sm) {
            ZStack {
                Circle().fill(Brand.gold.opacity(0.18))
                Image(systemName: symbol)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.bronze)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(Brand.secondary)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            Spacer(minLength: PremiumLayout.xs)
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.bronze)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
