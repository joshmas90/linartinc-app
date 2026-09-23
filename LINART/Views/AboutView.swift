import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmReset = false

    private var version: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                SectionHeading(eyebrow: "Family-owned since 2004", title: "The family name is on the work.")
                PortfolioImage(photo: ProjectPhoto(asset: "about-crew", caption: "LINART crew framing a residential addition in New Jersey"), height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Text("Linart Construction Inc. provides New Jersey homeowners with residential construction and remodeling services. Planning, site management, communication and finish quality are treated as parts of the same job.").lineSpacing(5)
                Text("New custom homes. Thoughtful additions. Carefully finished renovations.")
                    .font(.system(.title2, design: .serif))
                NavigationLink { ServiceAreasView() } label: {
                    Label("Explore our service area", systemImage: "map").frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.bordered)
                ContactActions()
                Button { store.startInquiry() } label: {
                    Label("Start a conversation", systemImage: "arrow.up.right")
                }.buttonStyle(PrimaryButtonStyle())
                Link(destination: Company.website) { Label("Visit linartinc.com", systemImage: "safari") }
                Divider()
                NavigationLink("Privacy & app information") { PrivacyView() }
                Button("Clear all local app data", role: .destructive) { confirmReset = true }
                Text("LINART · Version \(version)")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("About LINART").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear data saved in this app?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Clear local data", role: .destructive) {
                store.clearLocalData()
                try? StudioDraft.clear()
            }
        } message: { Text("Removes saved projects, checklist progress, the inquiry draft and your private Project Studio including photos. It does not delete inquiries already sent to LINART.") }
    }
}

struct ServiceAreasView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            Section {
                Text("New Jersey is home. So is the work.").font(.system(.title, design: .serif))
                Text("Most of our work is concentrated across these five counties, with select projects extending through Central and South Jersey.")
            }
            Section("Core service area") {
                ForEach(Company.coreCounties, id: \.self) { Label("\($0) County", systemImage: "mappin") }
            }
            Section("Outer project reach") {
                ForEach(Company.extendedCounties, id: \.self) { Text("\($0) County") }
            }
            Section("Occasional projects · availability varies") {
                ForEach(Company.occasionalCounties, id: \.self) { Text("\($0) County") }
            }
            Section {
                Text("Near the edge of our service area? Tell us where you are and what you are considering, and we’ll discuss whether the project is a fit.")
                Button("Discuss your location") { store.startInquiry() }
            }
        }
        .scrollContentBackground(.hidden).background(Brand.cream)
        .navigationTitle("Service areas").navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    var body: some View {
        List {
            Section("On your device") {
                Text("Saved project identifiers and checklist progress are stored in the app’s local preferences and may be included in your device backups. Use Clear saved projects and checklist in About to remove them.")
                Text("Inquiry drafts are kept in memory, not deliberately saved to disk by the app. They are cleared after a successful submission, when you choose Clear, or when the app process ends.")
                Text("Your optional Project Studio draft, inspiration links, notes and imported photo copies are stored on this device in protected app files. They may be included in device backups. Clear your studio from its screen, or clear all local data in About. Removing the app also removes its app data.")
            }
            Section("When you send an inquiry") {
                Text("The form sends your name, email, phone number, project city or ZIP, selected service, timing, preferred contact method and optional project description over HTTPS to linartinc.com/contact.php.")
                Text("LINART’s website service processes and stores inquiry details, records the request IP address and submission time, and emails the team so they can respond. Contact LINART about access to or deletion of an inquiry already sent.")
                Text("The app does not run advertising, tracking or analytics SDKs. The optional Project Studio uses the system photo picker to access only images you select; it does not request broad photo library, camera, contacts or device location permissions.")
            }
            Section("Optional cloud Project Studio") {
                Text("Verify your inquiry email with a one-time code to access only your projects. A short-lived session token is protected in this device’s Keychain. Sign out of Studio or clear local app data to remove it.")
                Text("Choosing photos or documents and typing answers saves them locally. Save progress to LINART or Submit uploads your chosen information over HTTPS into private Supabase storage and LINART’s project records. Saved cloud drafts are available to authorized LINART personnel; Submit marks the brief ready for review.")
                Text("We strip metadata from imported photo copies. PDF documents may retain their original metadata. Share only files you intend LINART to review. Removing a file takes effect in cloud storage when you next save. Clearing local data does not delete cloud records or previously emailed copies.")
                Text("Delete your Studio account and cloud projects from the Studio access screen. For access, correction or deletion of separate emailed inquiries and business records, contact services@linartinc.com. Private download links expire after 60 seconds. LINART does not sell Studio information or use it for advertising.")
            }
            Section("Other apps and services") {
                Text("Calling, emailing, sharing or opening the website hands control to the app or service you choose. Their own privacy practices apply. Sharing a project brief exports a PDF containing the information you entered and the photos you added. You choose a destination and whether to send it; LINART cannot confirm delivery from this app. Cloud Studio saves and submissions are securely associated with your original inquiry. An exported PDF is a separate copy.")
            }
            Section("Contact") { ContactActions() }
        }
        .scrollContentBackground(.hidden).background(Brand.cream)
        .navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
    }
}
