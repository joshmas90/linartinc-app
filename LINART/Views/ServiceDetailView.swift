import SwiftUI

struct ServiceDetailView: View {
    let service: Service
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "Residential expertise", title: service.title)
                PortfolioImage(photo: service.photo, height: 300).clipShape(RoundedRectangle(cornerRadius: 16))
                Text(service.introduction).lineSpacing(5)
                Text("Considered from the start").font(.system(.title2, design: .serif))
                ForEach(service.details, id: \.self) { detail in
                    Label(detail, systemImage: "checkmark").foregroundStyle(Brand.bronze)
                }
                Divider()
                ForEach(service.priorities, id: \.self) { priority in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(priority[0]).font(.headline)
                        Text(priority[1]).foregroundStyle(.secondary).lineSpacing(4)
                    }
                }
                Text(service.planning).lineSpacing(4).padding(20)
                    .background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
                Button { store.startInquiry(service: service.inquiryType) } label: {
                    Label("Discuss this service", systemImage: "arrow.up.right")
                }.buttonStyle(PrimaryButtonStyle())
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("Our services").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}
