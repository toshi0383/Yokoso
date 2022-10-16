import UIKit

public struct Instruction {

    public enum InteractionStyle {

        /// - Shows message
        /// - Only tappable inside cutoutPath
        /// - Does not close by itself
        case blocksTapOutsideCutoutPath

        /// - Shows message
        /// - Shows NextButton
        /// - Tap anywhere to close
        /// - "Tap through" inside cutoutPath while closing
        case nextButton(NSAttributedString)

        /// - Shows message
        /// - Tap anywhere to close
        /// - "Tap through" inside cutoutPath while closing
        case messageOnly

        var needsNextButton: Bool {
            guard case .nextButton = self else { return false }
            return true
        }

        var blocksTapOutsideCutoutPath: Bool {
            guard case .blocksTapOutsideCutoutPath = self else { return false }
            return true
        }
    }

    public struct Message {
        let attributedString: NSAttributedString
        let backgroundColor: UIColor
        let maxWidth: CGFloat

        public init(
            attributedString: NSAttributedString,
            backgroundColor: UIColor,
            maxWidth: CGFloat = 375
        ) {
            self.attributedString = attributedString
            self.backgroundColor = backgroundColor
            self.maxWidth = maxWidth
        }
    }

    let interactionStyle: InteractionStyle
    let message: Message
    let sourceView: UIView

    public init(style: InteractionStyle, message: Message, sourceView: UIView) {
        self.interactionStyle = style
        self.message = message
        self.sourceView = sourceView
    }
}
