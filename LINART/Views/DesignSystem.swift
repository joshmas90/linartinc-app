import SwiftUI

enum Brand {
    static let ink = Color(red: 11 / 255, green: 13 / 255, blue: 16 / 255)
    static let cream = Color(red: 245 / 255, green: 241 / 255, blue: 232 / 255)
    static let paper = Color(red: 255 / 255, green: 252 / 255, blue: 246 / 255)
    static let gold = Color(red: 215 / 255, green: 193 / 255, blue: 154 / 255)
    static let bronze = Color(red: 115 / 255, green: 80 / 255, blue: 36 / 255)
}

struct BrandHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("linart-seal")
                .resizable().scaledToFit().frame(width: 58, height: 58)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("LINART").font(.system(.title2, design: .serif, weight: .semibold)).tracking(3)
                Text("CONSTRUCTION INC.").font(.caption2.weight(.semibold)).tracking(1.4)
                Text("NEW JERSEY · SINCE 2004").font(.caption2).foregroundStyle(Brand.gold)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22).padding(.vertical, 16)
        .background(Brand.ink)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var light = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18).padding(.vertical, 17)
            .foregroundStyle(light ? Brand.ink : .white)
            .background(light ? Brand.gold : Brand.ink, in: RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.72 : 1)
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
        VStack(alignment: .leading, spacing: 0) {
            if let photo = project.photos.first { PortfolioImage(photo: photo) }
            VStack(alignment: .leading, spacing: 9) {
                Eyebrow(title: project.category)
                Text(project.title).font(.system(.title2, design: .serif)).foregroundStyle(Brand.ink)
                Label(project.location, systemImage: "mappin").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text("Explore project").font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .foregroundStyle(Brand.bronze).padding(.top, 7)
            }
            .padding(20)
        }
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 18))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Brand.gold.opacity(0.5)))
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct ContactActions: View {
    @Environment(\.openURL) private var openURL
    @State private var unavailable: String?

    var body: some View {
        VStack(spacing: 14) {
            Button {
                openURL(Company.phoneURL) { accepted in
                    if !accepted { unavailable = "Call LINART at \(Company.phone) from a phone." }
                }
            } label: {
                Label(Company.phone, systemImage: "phone").frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                openURL(Company.emailURL) { accepted in
                    if !accepted { unavailable = "Email \(Company.email) using your preferred email app." }
                }
            } label: {
                Label(Company.email, systemImage: "envelope").frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.body).buttonStyle(.bordered).tint(Brand.bronze)
        .alert("Contact LINART", isPresented: Binding(
            get: { unavailable != nil }, set: { if !$0 { unavailable = nil } }
        )) {
            Button("OK", role: .cancel) { unavailable = nil }
        } message: { Text(unavailable ?? "") }
    }
}
