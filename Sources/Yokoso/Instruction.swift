import UIKit

public struct Instruction {

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

    public enum NextButton {
        case simple(String)
        case custom(UIView)
    }

    /// If true:
    /// - Only tappable inside cutoutPath
    /// - Does not close by itself
    let blocksTapOutsideCutoutPath: Bool

    let message: Message
    let nextButton: NextButton?
    let sourceView: UIView

    public init(blocksTapOutsideCutoutPath: Bool, message: Message, nextButton: NextButton? = nil, sourceView: UIView) {
        if case .simple = nextButton, blocksTapOutsideCutoutPath {
            preconditionFailure("blocksTapOutsideCutoutPath must be false on simple NextButton.")
        }

        self.blocksTapOutsideCutoutPath = blocksTapOutsideCutoutPath
        self.message = message
        self.nextButton = nextButton
        self.sourceView = sourceView
    }
}
