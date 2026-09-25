import SwiftUI

struct MoreView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 18) {
                    Image("linart-residence-hero").resizable().scaledToFill()
                        .frame(width: 116, height: 116).clipShape(Circle())
                        .overlay(Circle().strokeBorder(Brand.gold, lineWidth: 2))
                        .accessibilityHidden(true)
                    BrandWordmark()
                }.padding(.vertical, 20)
                VStack(spacing: 10) {
                    NavigationLink { AboutView() } label: {
                        MenuRow(title: "About Us", subtitle: "The family behind the craftsmanship", symbol: "house")
                    }
                    NavigationLink { ContactView() } label: {
                        MenuRow(title: "Contact Us", subtitle: "Let’s talk about your home", symbol: "bubble.left.and.bubble.right")
                    }
                    NavigationLink { ServiceAreasView() } label: {
                        MenuRow(title: "Service Areas", subtitle: "At home in New Jersey", symbol: "map")
                    }
                    ShareLink(item: Company.website) {
                        MenuRow(title: "Share LINART", subtitle: "Introduce someone to our work", symbol: "square.and.arrow.up")
                    }
                    NavigationLink { PrivacyView() } label: {
                        MenuRow(title: "Privacy", subtitle: "Your information, thoughtfully handled", symbol: "hand.raised")
                    }
                    NavigationLink { SettingsView() } label: {
                        MenuRow(title: "Settings", subtitle: "App information and saved data", symbol: "gearshape")
                    }
                }.buttonStyle(.plain)
                VStack(spacing: 16) {
                    Text("Building Better\nLives at Home")
                        .font(.system(.title2, design: .serif)).italic().multilineTextAlignment(.center)
                    Rectangle().fill(Brand.brass).frame(width: 44, height: 1)
                }.frame(maxWidth: .infinity).padding(28)
                    .background(Brand.line.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("More").navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SectionHeading(eyebrow: "A considered beginning", title: "Tell us what you have in mind.")
                Text("A new home, a little more room, or a space that works better for you. We’d love to hear about it.")
                    .foregroundStyle(Brand.secondary).lineSpacing(5)
                Button("Start a Project Inquiry") { store.startInquiry() }.buttonStyle(PrimaryButtonStyle())
                ContactActions()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("Contact Us").navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var studio: StudioStore
    @EnvironmentObject private var cloud: CloudStudioStore
    @State private var confirmReset = false
    @State private var resetError: String?

    var body: some View {
        List {
            Section("LINART") {
                LabeledContent("Version", value: (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0")
                LabeledContent("Build", value: (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1")
                Button {
                    store.selectedTab = .home
                    store.introductionReplayRequested = true
                } label: {
                    Label("Replay welcome", systemImage: "play.circle")
                }
            }
            Section("Help with the app") {
                ShareLink(item: Diagnostics.shared.summary) { Label("Share app diagnostics", systemImage: "doc.text") }
                Text("Includes app version and recent error categories only. No names, contact details, photos, notes or account tokens.").font(.caption)
            }
            Section {
                Button("Clear all local app data", role: .destructive) { confirmReset = true }.disabled(studio.state == .clearing)
            } header: { Text("Saved on this device") } footer: {
                Text("Removes saved ideas, checklist progress, the inquiry draft and private project photos and notes. Inquiries already sent to LINART are unaffected.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.cream)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: PremiumLayout.tabBarClearance)
        }
        .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Clear data saved in this app?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Clear local data", role: .destructive) {
                    Task {
                        do {
                            try await studio.clear()
                            try await store.clearSavedInquiry()
                            try await cloud.clearLocal()
                            store.clearLocalData()
                            Diagnostics.shared.clear()
                        } catch { resetError = "Your saved files could not be cleared. Please try again." }
                    }
                }
            }
            .alert("Unable to clear data", isPresented: Binding(get: { resetError != nil }, set: { if !$0 { resetError = nil } })) {
                Button("OK", role: .cancel) { resetError = nil }
            } message: { Text(resetError ?? "") }
    }
}

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
                    Label("Explore our service area", systemImage: "map")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(SecondaryButtonStyle())
                ContactActions()
                Button { store.startInquiry() } label: {
                    Label("Start a conversation", systemImage: "arrow.up.right")
                }.buttonStyle(PrimaryButtonStyle())
                Link(destination: Company.website) {
                    Label("Visit linartinc.com", systemImage: "safari")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(TertiaryButtonStyle())
                Divider().overlay(Brand.line)
                NavigationLink { PrivacyView() } label: {
                    MenuRow(title: "Privacy & app information", subtitle: "How information is handled", symbol: "hand.raised")
                }
                .buttonStyle(.plain)
                NavigationLink { SettingsView() } label: {
                    MenuRow(title: "Manage saved app data", subtitle: "Settings, diagnostics and local data", symbol: "gearshape")
                }
                .buttonStyle(.plain)
                Text("LINART · Version \(version)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("About LINART").navigationBarTitleDisplayMode(.inline)

    }
}

struct ServiceAreasView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PremiumLayout.lg) {
                VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                    SectionHeading(eyebrow: "New Jersey", title: "Close to home. Close to the work.")
                    Text("Most LINART projects are concentrated across our core counties, with select work extending through Central and South Jersey.")
                        .foregroundStyle(Brand.secondary)
                        .lineSpacing(4)
                }

                ServiceAreaGroup(
                    eyebrow: "Primary coverage",
                    title: "Core service area",
                    counties: Company.coreCounties,
                    emphasized: true
                )

                ServiceAreaGroup(
                    eyebrow: "Select projects",
                    title: "Outer project reach",
                    counties: Company.extendedCounties
                )

                ServiceAreaGroup(
                    eyebrow: "Availability varies",
                    title: "Occasional projects",
                    counties: Company.occasionalCounties
                )

                VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                    Rectangle().fill(Brand.brass).frame(width: 42, height: 2)
                    Eyebrow(title: "Just outside the map?")
                    Text("Tell us where you are.")
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(Brand.ink)
                    Text("Project type, schedule and location all matter. If you're near the edge of our service area, we'll tell you directly whether the project is a fit.")
                        .foregroundStyle(Brand.secondary)
                        .lineSpacing(4)
                    Button("Discuss your location") { store.startInquiry() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("Service areas")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ServiceAreaGroup: View {
    let eyebrow: String
    let title: String
    let counties: [String]
    var emphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: PremiumLayout.md) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(title: eyebrow)
                Text(title)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Brand.ink)
            }

            VStack(spacing: 0) {
                ForEach(Array(counties.enumerated()), id: \.element) { index, county in
                    HStack(spacing: PremiumLayout.sm) {
                        if emphasized {
                            Image(systemName: "mappin")
                                .font(.subheadline)
                                .foregroundStyle(Brand.bronze)
                                .frame(width: 18)
                                .accessibilityHidden(true)
                        }
                        Text("\(county) County")
                            .font(.body)
                            .foregroundStyle(Brand.ink)
                        Spacer()
                    }
                    .frame(minHeight: 48)
                    if index < counties.count - 1 {
                        Divider().overlay(Brand.line)
                    }
                }
            }
        }
        .padding(PremiumLayout.md)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
    }
}

struct PrivacyView: View {
    var body: some View {
        List {
            Section("On your device") {
                Text("Saved project identifiers and checklist progress are stored in the app’s local preferences and may be included in your device backups. Use Clear all local app data in More → Settings to remove them.")
                Text("Inquiry drafts remain in memory unless you enable Save this inquiry on my device. That option saves the draft in protected app files, which may be included in device backups. A successful submission or Clear removes the saved copy; deletion failures are reported.")
                Text("Your optional My Project draft, inspiration links, notes and imported photo copies are stored on this device in protected app files. They may be included in device backups. Clear your project from My Project, or clear all local data in More → Settings. Removing the app also removes its app data.")
            }
            Section("When you send an inquiry") {
                Text("The form sends your name, email, phone number, project city or ZIP, selected service, timing, preferred contact method and optional project description over HTTPS to linartinc.com/contact.php.")
                Text("LINART’s website service processes and stores inquiry details, records the request IP address and submission time, and emails the team so they can respond. Contact LINART about access to or deletion of an inquiry already sent.")
                Text("The app does not run advertising, tracking or analytics SDKs. My Project uses the system photo picker to access only images you select; it does not request broad photo library, camera, contacts or device location permissions.")
            }
            Section("Other apps and services") {
                Text("Calling, emailing, sharing or opening the website hands control to the app or service you choose. Their own privacy practices apply. Sharing a project brief exports a PDF containing the information you entered and the photos you added. You choose a destination and whether to send it; LINART cannot confirm delivery from this app. Your initial inquiry and shared PDF are not automatically linked by the server.")
            }
            Section("Optional project brief submissions") {
                Text("When you sign in and choose Send my brief, your email-verified account, project answers, links, saved ideas and selected photo copies are processed by Supabase for LINART. App submissions use separate private storage and app-specific database tables. Nothing is uploaded during ordinary local planning.")
                Text("Sign-in emails are sent through LINART’s Hostinger email service. Sign-in tokens are stored in the device Keychain and may survive reinstalling the app. Sign out to remove this device’s saved session. Clear local data does not delete a cloud submission; use My Project → Sent briefs & account → Your app submissions to delete it and its uploaded photos.")
                Text("To delete your account, open My Project → Sent briefs & account → Delete my app account. App uploads are removed immediately and new uploads are disabled. LINART completes the account-deletion request within 7 days and confirms by email, reviewing any shared LINART records separately. Your local project draft is kept until you clear it.")
                Text("A receipt confirms server storage only. LINART may already have downloaded a copy when you request deletion. Email services@linartinc.com for help with account records or information already received by the team.")
            }
            Section("Contact") { ContactActions() }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.cream)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: PremiumLayout.tabBarClearance)
        }
        .navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
    }
}
