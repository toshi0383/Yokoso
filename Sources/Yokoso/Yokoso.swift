import UIKit

/// Supporting device rotation.
let overlayOuterMargin: CGFloat = 500

@MainActor
public final class InstructionManager {

    private weak var window: UIWindow?
    private var onFinish: ((Bool) -> ())?

    public var isStarted: Bool { window != nil }
    private let overlayBackgroundColor: UIColor
    private var instruction: Instruction?

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
            } completion: { _ in
                oldValue?.removeFromSuperview()
            }
        }
    }

    public init(overlayBackgroundColor: UIColor = .black.withAlphaComponent(0.4)) {
        self.overlayBackgroundColor = overlayBackgroundColor
    }

    public func show(_ instruction: Instruction, in view: UIView) async throws {
        try await withCheckedThrowingContinuation { c in
            do {
                try self.show(instruction, in: view, onFinish: { isSuccessful in
                    if isSuccessful {
                        c.resume()
                    } else {
                        c.resume(throwing: InstructionError.interestedViewOutOfBounds)
                    }
                })
            } catch {
                c.resume(throwing: error)
            }
        }
    }

    /// - throws: `InstructionError.interestedViewOutOfBounds`
    public func show(
        _ instruction: Instruction,
        in view: UIView,
        onFinish: @escaping (Bool) -> ()
    ) throws {
        window = view.window
        self.onFinish = onFinish

        try _show(instruction)
    }

    private func _show(_ instruction: Instruction) throws {

        guard let window else { return }

        guard var sourceViewFrameInWindow = instruction.sourceView.superview?.convert(instruction.sourceView.frame, to: window) else {
            return
        }

            self.instruction = instruction

        if let sourceRect = instruction.sourceRect {
            sourceViewFrameInWindow = CGRect(
                x: sourceViewFrameInWindow.minX + sourceRect.minX,
                y: sourceViewFrameInWindow.minY + sourceRect.minY,
                width: sourceRect.size.width,
                height: sourceRect.size.height
            )
        }

        sourceViewFrameInWindow.expand(instruction.cutoutPathExpansion)

        if sourceViewFrameInWindow.minX < 0
            || sourceViewFrameInWindow.minY < 0
            || sourceViewFrameInWindow.maxY > window.bounds.height
            || sourceViewFrameInWindow.maxX > window.bounds.width
        {
            dismissOverlayAnimated()
            throw InstructionError.interestedViewOutOfBounds
        }

        let overlay = OverlayView(
            backgroundColor: overlayBackgroundColor,
            cutoutCornerRadius: instruction.cutoutCornerRadius
        )
        self.overlay = overlay

        let sourceViewX = sourceViewFrameInWindow.minX + overlayOuterMargin
        let sourceViewY = sourceViewFrameInWindow.minY + overlayOuterMargin
        let cutoutX = sourceViewX
        let cutoutY = sourceViewY
        let cutoutCenterX = cutoutX + sourceViewFrameInWindow.width / 2
        let cutoutHeight = sourceViewFrameInWindow.height

        let expanded = CGRect(
            x: cutoutX,
            y: cutoutY,
            width: sourceViewFrameInWindow.width,
            height: cutoutHeight
        )

        overlay.cutoutPath = expanded
        overlay.blocksTapInsideCutoutPath = instruction.blocksTapInsideCutoutPath

        let messageLabel = MessageLabel(instruction)

        if !instruction.blocksTapOutsideCutoutPath || !instruction.blocksTapInsideCutoutPath {
            overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapOverlay)))
        }
        messageLabel.onTapNext = { [weak self] in self?.close() }

        overlay.onHitInsideCutoutPath = { [weak self] in
            if !instruction.ignoresTapInsideCutoutPath {
                self?.close()
            }
        }

        overlay.onWidthChanged = { [weak self] in

            // - NOTE: Supporting device rotation / iPad SplitView
            // - HACK: Layout is not fixed in original window at this time, so check interested frame after some delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) { [weak self] in
                guard let me = self else { return }

                do {
                    try me._show(instruction)
                } catch {
                    me.close(unexpectedly: true)
                }
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

    @objc private func onTapOverlay(_ gesture: UITapGestureRecognizer) {
        guard let instruction else { return }
        let isTapInsideCutoutPath = overlay?.cutoutPath?.contains(gesture.location(in: overlay)) == true
        if (instruction.blocksTapInsideCutoutPath || instruction.ignoresTapInsideCutoutPath), isTapInsideCutoutPath {
            return
        }

        if instruction.blocksTapOutsideCutoutPath, !isTapInsideCutoutPath {
            return
        }

        close()
    }

    private var isClosing = false

    @objc public func close(unexpectedly: Bool = false) {
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
            me.onFinish?(!unexpectedly)
        }

        window = nil
        instruction = nil

        dismissOverlayAnimated()
    }

    private func dismissOverlayAnimated() {
        UIView.animate(withDuration: 0.3) { [weak overlay] in
            overlay?.alpha = 0
        }
    }
}
