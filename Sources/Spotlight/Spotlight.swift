import UIKit

/// Supporting device rotation.
let overlayOuterMargin: CGFloat = 500

public final class InstructionManager {

    public struct Instruction {

        public enum InteractionStyle {

            /// - Shows message
            /// - Only tappable inside cutoutPath
            /// - Does not close by itself
            case blocksTapBesidesCutoutPath

            /// - Shows message
            /// - Shows NextButton
            /// - Tap anywhere to close
            /// - "Tap through" inside cutoutPath while closing
            case nextButton

            /// - Shows message
            /// - Tap anywhere to close
            /// - "Tap through" inside cutoutPath while closing
            case messageOnly
        }

        public struct Message {
            let attributedString: NSAttributedString
            let backgroundColor: UIColor

            public init(attributedString: NSAttributedString, backgroundColor: UIColor) {
                self.attributedString = attributedString
                self.backgroundColor = backgroundColor
            }
        }

        let style: InteractionStyle
        let message: Message
        let sourceView: UIView

        public init(style: InteractionStyle, message: Message, sourceView: UIView) {
            self.style = style
            self.message = message
            self.sourceView = sourceView
        }
    }

    private weak var window: UIWindow?
    private var onFinish: (() -> ())?

    public var isStarted: Bool { window != nil }

    private var overlay: OverlayView? {
        didSet {
            guard let w = window, let overlay else { return }

            overlay.alpha = 0
            w.addSubview(overlay)
            overlay.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: w.topAnchor, constant: -overlayOuterMargin),
                overlay.bottomAnchor.constraint(equalTo: w.bottomAnchor, constant: overlayOuterMargin),
                overlay.leadingAnchor.constraint(equalTo: w.leadingAnchor, constant: -overlayOuterMargin),
                overlay.trailingAnchor.constraint(equalTo: w.trailingAnchor, constant: overlayOuterMargin),
            ])

            // HACK:
            //   Need to fix overlay's frame here.
            //   I coundn't support device rotation with frame layout, so sticking with AutoLayout.
            //   Looks like expensive code though.
            w.layoutIfNeeded()

            UIView.animate(withDuration: 0.3) {
                oldValue?.alpha = 0
                overlay.alpha = 1
            }
        }
    }

    public init() {}

    /// - throws: `SpotlightError.interestedViewOutOfBounds`
    public func show(
        _ instruction: Instruction,
        in view: UIView,
        onFinish: @escaping () -> ()
    ) throws {
        window = view.window
        self.onFinish = onFinish

        try _show(instruction)
    }

    private func _show(_ instruction: Instruction) throws {
        overlay = OverlayView()

        guard let window, let overlay else { return }

        guard let sourceViewFrameInWindow = instruction.sourceView.superview?.convert(instruction.sourceView.frame, to: window) else {
            return
        }

        if sourceViewFrameInWindow.minX < 0 || sourceViewFrameInWindow.minY < 0 {
            throw SpotlightError.interestedViewOutOfBounds
        }

        let sourceViewX = sourceViewFrameInWindow.minX + overlayOuterMargin
        let sourceViewY = sourceViewFrameInWindow.minY + overlayOuterMargin
        let cutoutX = sourceViewX - 4
        let cutoutY = sourceViewY - 4
        let cutoutCenterX = cutoutX + sourceViewFrameInWindow.width / 2
        let cutoutHeight = sourceViewFrameInWindow.height + 8

        let expanded = CGRect(
            x: cutoutX,
            y: cutoutY,
            width: sourceViewFrameInWindow.width + 8,
            height: cutoutHeight
        )

        overlay.cutoutPath = expanded

        if instruction.style != .blocksTapBesidesCutoutPath {
            overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        }

        overlay.onHitInsideCutoutPath = { [weak self] in self?.close() }

        overlay.onWidthChanged = { [weak self] in

            // - NOTE: Supporting device rotation / iPad SplitView
            // - HACK: Layout is not fixed in original window at this time, so check interested frame after some delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) { [weak self] in
                try? self?._show(instruction)
            }

        }

        let label = UILabel()
        label.attributedText = instruction.message.attributedString
        label.numberOfLines = 0
        let container = UIView()
        container.layer.cornerRadius = 5
        container.backgroundColor = instruction.message.backgroundColor

        let arrow = UIView()
        arrow.layer.cornerRadius = 5
        arrow.backgroundColor = instruction.message.backgroundColor
        arrow.transform = CGAffineTransform(rotationAngle: 45 * CGFloat.pi / 180)

        [label, container, arrow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let rectHeight: CGFloat = 30
        let arrowHeight: CGFloat = rectHeight * sqrt(2) / 2
        let labelPadding: CGFloat = 15

        container.constrainSubview(label, horizontal: labelPadding, vertical: labelPadding)
        overlay.addSubview(container)
        overlay.addSubview(arrow)

        NSLayoutConstraint.activate([
            arrow.widthAnchor.constraint(equalToConstant: 30),
            arrow.heightAnchor.constraint(equalToConstant: 30),
            arrow.centerXAnchor.constraint(equalTo: overlay.leadingAnchor, constant: cutoutCenterX),
            container.centerXAnchor.constraint(equalTo: overlay.leadingAnchor, constant: cutoutCenterX).priority(.defaultLow),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 15),
            container.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -15),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: window.frame.width - window.safeAreaInsets.right - window.safeAreaInsets.left - 30),
        ])

        let arrowConstraints: [NSLayoutConstraint] = {

            container.layoutIfNeeded()

            if sourceViewFrameInWindow.minY < container.frame.height + rectHeight {
                // does not fit in top margin
                return [
                    arrow.topAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY + cutoutHeight + 10),
                    container.topAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY + cutoutHeight + 2 + arrowHeight),
                ]
            } else {
                return [
                    arrow.bottomAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY - 10),
                    container.bottomAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY - 2 - arrowHeight),
                ]
            }
        }()

        NSLayoutConstraint.activate(arrowConstraints)
    }

    private var isClosing = false

    @objc private func close() {
        guard let overlay, !isClosing else { return }

        isClosing = true
        overlay.onHitInsideCutoutPath = nil
        overlay.onWidthChanged = nil

        // NOTE:
        //   If close is triggered by hitTest, then `onFinish` call would conflict with client's tap event handling.
        //   Let's delay this by default.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
            guard let me = self else { return }

            me.isClosing = false
            me.onFinish?()
        }

        window = nil

        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 0
        }
    }
}
