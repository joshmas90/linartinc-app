import Foundation

struct Inquiry: Codable, Equatable {
    var name = ""
    var email = ""
    var phone = ""
    var city = ""
    var service = "New Custom Home Construction"
    var timing = ""
    var contact = ""
    var message = ""
    var company = ""
    var request_id = UUID().uuidString.lowercased()

    static let serviceOptions = [
        "New Custom Home Construction", "Home Addition", "Whole-Home Renovation",
        "Kitchen Remodeling", "Bathroom Remodeling", "Basement Finishing",
        "Deck / Patio Construction", "Other Residential Work"
    ]
    static let timingOptions = ["Planning / researching", "Within 3 months", "3–6 months", "6–12 months", "12+ months"]
    static let contactOptions = ["Phone", "Email", "Text"]

    var normalized: Inquiry {
        var value = self
        value.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        value.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        value.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        value.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        value.message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        value.company = ""
        return value
    }

    var validationErrors: [String: String] {
        let value = normalized
        var errors: [String: String] = [:]
        if value.name.isEmpty || value.name.count > 120 {
            errors["name"] = "Enter your name, up to 120 characters."
        }
        if value.email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) == nil || value.email.count > 180 {
            errors["email"] = "Enter a valid email address."
        }
        let digits = value.phone.filter { $0 >= "0" && $0 <= "9" }
        if digits.count < 10 || value.phone.count > 60 {
            errors["phone"] = "Enter a phone number with at least 10 digits."
        }
        if value.city.isEmpty || value.city.count > 120 {
            errors["city"] = "Enter the project city or ZIP, up to 120 characters."
        }
        if !Self.serviceOptions.contains(value.service) {
            errors["service"] = "Choose a project type."
        }
        if !value.timing.isEmpty && !Self.timingOptions.contains(value.timing) {
            errors["timing"] = "Choose a project timing or leave it blank."
        }
        if !value.contact.isEmpty && !Self.contactOptions.contains(value.contact) {
            errors["contact"] = "Choose how we should contact you."
        }
        if value.message.count > 1000 {
            errors["message"] = "Keep your project description within 1,000 characters."
        }
        return errors
    }

    var brief: String {
        """
        LINART project inquiry

        Name: \(name)
        Email: \(email)
        Phone: \(phone)
        City / ZIP: \(city)
        Project type: \(service)
        Timing: \(timing.isEmpty ? "Not specified" : timing)
        Preferred contact: \(contact)

        \(message.isEmpty ? "No additional details provided." : message)
        """
    }

    var emailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Company.email
        components.queryItems = [
            URLQueryItem(name: "subject", value: "LINART inquiry — \(service) — \(city)"),
            URLQueryItem(name: "body", value: brief)
        ]
        return components.url
    }
}
