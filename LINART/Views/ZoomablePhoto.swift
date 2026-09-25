import SwiftUI
import UIKit

struct ZoomablePhoto: UIViewRepresentable {
    let asset: String
    let caption: String
    func makeUIView(context: Context) -> PhotoScrollView { PhotoScrollView() }
    func updateUIView(_ view: PhotoScrollView, context: Context) { view.setPhoto(asset: asset, caption: caption) }
}

final class PhotoScrollView: UIScrollView, UIScrollViewDelegate {
    private let photograph = UIImageView()
    private var assetName: String?
    private var previousSize = CGSize.zero
    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self; minimumZoomScale = 1; maximumZoomScale = 4
        showsHorizontalScrollIndicator = false; showsVerticalScrollIndicator = false
        photograph.contentMode = .scaleAspectFit; addSubview(photograph)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleZoom))
        doubleTap.numberOfTapsRequired = 2; addGestureRecognizer(doubleTap)
        isAccessibilityElement = true
        accessibilityCustomActions = [UIAccessibilityCustomAction(name: "Zoom in", target: self, selector: #selector(zoomIn)), UIAccessibilityCustomAction(name: "Reset zoom", target: self, selector: #selector(zoomOut))]
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func setPhoto(asset: String, caption: String) {
        accessibilityLabel = caption; accessibilityHint = "Pinch or double tap to zoom. Swipe to explore other photos when zoom is reset."
        guard assetName != asset else { return }
        assetName = asset; photograph.image = UIImage(named: asset)
        setZoomScale(1, animated: false); previousSize = .zero; setNeedsLayout()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if previousSize != bounds.size {
            setZoomScale(1, animated: false); photograph.frame = CGRect(origin: .zero, size: bounds.size)
            contentSize = bounds.size; previousSize = bounds.size
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { photograph }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { accessibilityValue = "\(Int(zoomScale * 100)) percent" }
    @objc private func toggleZoom() { setZoomScale(zoomScale > 1 ? 1 : 2.5, animated: !UIAccessibility.isReduceMotionEnabled) }
    @objc private func zoomIn() -> Bool { setZoomScale(min(4, zoomScale + 1), animated: false); return true }
    @objc private func zoomOut() -> Bool { setZoomScale(1, animated: false); return true }
}
