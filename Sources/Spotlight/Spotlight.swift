import UIKit

/// Supporting device rotation.
let overlayOuterMargin: CGFloat = 500

public final class InstructionManager {

    public struct Instruction {

        public enum InteractionStyle {

            /// メッセージを表示する
            /// cutoutPath内をタップさせる
            /// 自分がタップされても閉じない
            case blocksTapBesidesCutoutPath

            /// メッセージを表示する
            /// 次へボタンを表示する
            /// どこを押しても閉じる
            /// cutoutPath内だけはタップ有効で、この場合も閉じる
            case nextButton

            /// メッセージを表示する
            /// どこを押しても閉じる
            /// cutoutPath内だけはタップ有効で、この場合も閉じる
            case messageOnly
        }

        let style: InteractionStyle
        let message: NSAttributedString
        let sourceView: UIView

        public init(style: InteractionStyle, message: NSAttributedString, sourceView: UIView) {
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
            //   I coundn't support device rotation with frame layout,
            //   so sticking with AutoLayout here.
            //   Looks like expensive code though.
            w.layoutIfNeeded()

            UIView.animate(withDuration: 0.3) {
                oldValue?.alpha = 0
                overlay.alpha = 1
            }
        }
    }

    public init() {}

    public func show(
        _ instruction: Instruction,
        in view: UIView,
        onFinish: @escaping () -> ()
    ) {
        window = view.window
        self.onFinish = onFinish

        _show(instruction)
    }

    private func _show(_ instruction: Instruction) {
        overlay = OverlayView()

        guard let window, let overlay else { return }

        guard let sourceViewFrameInWindow = instruction.sourceView.superview?.convert(instruction.sourceView.frame, to: window) else {
            return
        }

        let expanded = CGRect(
            x: sourceViewFrameInWindow.minX - 4 + overlayOuterMargin,
            y: sourceViewFrameInWindow.minY - 4 + overlayOuterMargin,
            width: sourceViewFrameInWindow.width + 8,
            height: sourceViewFrameInWindow.height + 8
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
                self?._show(instruction)
            }

        }
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
