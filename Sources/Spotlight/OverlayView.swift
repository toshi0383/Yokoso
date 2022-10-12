import UIKit

final class OverlayView: UIView {

    var cutoutPath: CGRect? {
        didSet {
            reloadLayers()
        }
    }

    var onWidthChanged: (() -> ())?
    var onHitInsideCutoutPath: (() -> ())?
    private var preWidth: CGFloat?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .black.withAlphaComponent(0.4)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = frame.width

        if let preWidth, preWidth != width, width > 0 {
            onWidthChanged?()
        }

        preWidth = width
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let cutoutPath, cutoutPath.contains(point) {
            onHitInsideCutoutPath?()
            return nil
        }

        return super.hitTest(point, with: event)
    }

    private func reloadLayers() {
        guard let cutoutPath else { return }

        let path = UIBezierPath(rect: cutoutPath)
        path.append(UIBezierPath(rect: bounds))

        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path.cgPath

        layer.mask = maskLayer
    }
}
