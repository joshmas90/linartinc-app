import Foundation
import UIKit
import CoreText
import ImageIO

enum StudioExportMode: String, CaseIterable, Identifiable, Sendable {
    case summary = "Summary", projectBook = "Project book"
    var id: String { rawValue }
}

enum StudioPDF {
    private static let page = CGRect(x: 0, y: 0, width: 612, height: 792)
    private static let textRect = CGRect(x: 46, y: 76, width: 520, height: 644)

    static func create(draft: StudioDraft, mode: StudioExportMode, photoDirectory: URL, outputDirectory: URL) throws -> URL {
        let text: String
        if mode == .summary {
            text = """
            \(draft.displayTitle)

            WHAT I WANT TO ACHIEVE
            \(draft.goals.isEmpty ? "To discuss together" : draft.goals)

            PRIORITIES
            \(draft.priorities.isEmpty ? "To discuss together" : draft.priorities)

            INVESTMENT & TIMING
            \(draft.investment.isEmpty ? "Not specified" : draft.investment)
            \(draft.timeline.isEmpty ? "Not specified" : draft.timeline)

            CONTACT
            \(draft.inquiryEmail.isEmpty ? "Not provided" : draft.inquiryEmail)

            \(draft.photos.count) photos and \(draft.ideas.count) saved ideas are held in the homeowner’s project draft. Choose Project book to include the complete details and photographs.

            This is a homeowner-prepared brief, not an estimate, booking or delivery receipt.
            """
        } else { text = draft.brief }

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        paragraph.paragraphSpacing = 8
        let attributed = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor(white: 0.16, alpha: 1), .paragraphStyle: paragraph
        ])
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let path = CGPath(rect: CGRect(origin: .zero, size: textRect.size), transform: nil)
        var ranges: [CFRange] = []
        var offset = 0
        while offset < attributed.length {
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: offset, length: 0), path, nil)
            let visible = CTFrameGetVisibleStringRange(frame)
            guard visible.length > 0 else { throw StudioStorageError.unreadableDraft }
            ranges.append(visible)
            offset += visible.length
        }
        let photos = mode == .projectBook ? draft.photos : []
        // Validate every photo first so the export cannot silently omit a missing file.
        for photo in photos {
            guard photo.filename == (photo.filename as NSString).lastPathComponent,
                  !photo.filename.contains(".."), !photo.filename.contains("\\"),
                  let image = CGImageSourceCreateWithURL(photoDirectory.appendingPathComponent(photo.filename) as CFURL, nil),
                  CGImageSourceGetCount(image) > 0 else { throw StudioStorageError.missingPhoto }
        }
        let totalPages = 1 + ranges.count + photos.count
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { context in
            context.beginPage()
            UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1).setFill()
            context.cgContext.fill(page)
            draw("LINART", rect: CGRect(x: 46, y: 74, width: 520, height: 58), size: 40, serif: true)
            draw("BUILD · RENOVATE · IMPROVE", rect: CGRect(x: 48, y: 138, width: 500, height: 30), size: 11)
            draw(mode.rawValue.uppercased(), rect: CGRect(x: 48, y: 294, width: 516, height: 28), size: 11)
            draw(draft.displayTitle, rect: CGRect(x: 46, y: 332, width: 520, height: 150), size: 32, serif: true)
            draw(Date().formatted(date: .long, time: .omitted), rect: CGRect(x: 48, y: 532, width: 500, height: 30), size: 12)
            draw("Prepared by the homeowner\nShared only when you choose a destination and send it.", rect: CGRect(x: 48, y: 580, width: 510, height: 65), size: 12)
            footer(pageNumber: 1, total: totalPages)
            for (index, range) in ranges.enumerated() {
                context.beginPage()
                draw("LINART  /  PROJECT DETAILS", rect: CGRect(x: 46, y: 34, width: 520, height: 25), size: 10)
                let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
                let cg = context.cgContext
                cg.saveGState()
                cg.translateBy(x: textRect.minX, y: textRect.maxY)
                cg.scaleBy(x: 1, y: -1)
                cg.textMatrix = .identity
                CTFrameDraw(frame, cg)
                cg.restoreGState()
                footer(pageNumber: index + 2, total: totalPages)
            }
            for (index, photo) in photos.enumerated() {
                context.beginPage()
                draw("PHOTO \(index + 1)  /  \(photo.purpose.uppercased())", rect: CGRect(x: 46, y: 36, width: 520, height: 35), size: 12)
                if let image = UIImage(contentsOfFile: photoDirectory.appendingPathComponent(photo.filename).path) {
                    let available = CGSize(width: 520, height: 575)
                    let scale = min(available.width / image.size.width, available.height / image.size.height)
                    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    image.draw(in: CGRect(x: (page.width - size.width) / 2, y: 90 + (575 - size.height) / 2, width: size.width, height: size.height))
                }
                draw(photo.note.isEmpty ? "\(photo.purpose) · Homeowner-selected photograph" : "Full photo notes appear in Project Details, under Photographs.", rect: CGRect(x: 46, y: 686, width: 520, height: 35), size: 10)
                footer(pageNumber: 2 + ranges.count + index, total: totalPages)
            }
        }
        let url = outputDirectory.appendingPathComponent("LINART-\(mode == .summary ? "Summary" : "Project-Book")-\(UUID().uuidString).pdf")
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        return url
    }

    private static func draw(_ text: String, rect: CGRect, size: CGFloat, serif: Bool = false) {
        let font = serif ? (UIFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)) : UIFont.systemFont(ofSize: size)
        (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: UIColor(white: 0.16, alpha: 1)])
    }
    private static func footer(pageNumber: Int, total: Int) {
        draw("LINART  ·  PROJECT BRIEF", rect: CGRect(x: 46, y: 749, width: 370, height: 18), size: 9)
        draw("\(pageNumber) / \(total)", rect: CGRect(x: 516, y: 749, width: 50, height: 18), size: 9)
    }
}
