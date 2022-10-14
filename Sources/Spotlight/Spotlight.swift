import UIKit

/// Supporting device rotation.
let overlayOuterMargin: CGFloat = 500

public final class InstructionManager {

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

        if sourceViewFrameInWindow.minX < 0
            || sourceViewFrameInWindow.minY < 0
            || sourceViewFrameInWindow.maxY > window.bounds.height
            || sourceViewFrameInWindow.maxX > window.bounds.width
        {
            dismissOverlayAnimated()
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

        let messageLabel = MessageLabel(instruction)

        switch instruction.interactionStyle {
        case .nextButton:
            overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
            messageLabel.onTapNext = { [weak self] in self?.close() }
        case .messageOnly:
            overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        case .blocksTapOutsideCutoutPath:
            break
        }

        overlay.onHitInsideCutoutPath = { [weak self] in self?.close() }

        overlay.onWidthChanged = { [weak self] in

            // - NOTE: Supporting device rotation / iPad SplitView
            // - HACK: Layout is not fixed in original window at this time, so check interested frame after some delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) { [weak self] in
                try? self?._show(instruction)
            }

        }

        let arrow = UIView()
        arrow.layer.cornerRadius = 5
        arrow.backgroundColor = instruction.message.backgroundColor
        arrow.transform = CGAffineTransform(rotationAngle: 45 * CGFloat.pi / 180)

        [messageLabel, arrow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let rectHeight: CGFloat = 30
        let arrowHeight: CGFloat = rectHeight * sqrt(2) / 2

        overlay.addSubview(arrow) // NOTE: `arrow` has to be below mesasge `container`
        overlay.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            arrow.widthAnchor.constraint(equalToConstant: 30),
            arrow.heightAnchor.constraint(equalToConstant: 30),
            arrow.centerXAnchor.constraint(equalTo: overlay.leadingAnchor, constant: cutoutCenterX).priority(.defaultLow),
            arrow.leadingAnchor.constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            arrow.trailingAnchor.constraint(lessThanOrEqualTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -5),
            arrow.leadingAnchor.constraint(greaterThanOrEqualTo: messageLabel.leadingAnchor, constant: 10),
            arrow.trailingAnchor.constraint(lessThanOrEqualTo: messageLabel.trailingAnchor, constant: 10),
            messageLabel.centerXAnchor.constraint(equalTo: overlay.leadingAnchor, constant: cutoutCenterX).priority(.defaultLow),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -5),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: window.frame.width - window.safeAreaInsets.right - window.safeAreaInsets.left - 30),
        ])

        // Deciding arrow direction
        let arrowConstraints: [NSLayoutConstraint] = {

            messageLabel.layoutIfNeeded()

            if window.frame.height - sourceViewFrameInWindow.maxY < messageLabel.frame.height + rectHeight {
                return [
                    arrow.bottomAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY - 10),
                    messageLabel.bottomAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY - 2 - arrowHeight),
                ]
            } else {
                return [
                    arrow.topAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY + cutoutHeight + 10),
                    messageLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: cutoutY + cutoutHeight + 2 + arrowHeight),
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

        dismissOverlayAnimated()
    }

    private func dismissOverlayAnimated() {
        UIView.animate(withDuration: 0.3) { [weak overlay] in
            overlay?.alpha = 0
        }
    }
}
