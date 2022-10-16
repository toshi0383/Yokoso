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

    let message: Message
    let nextButton: NextButton?
    let sourceView: UIView
    let blocksTapOutsideCutoutPath: Bool

    /// - parameter message: message struct value
    /// - parameter nextButton: NextButton enum value. Default: nil
    /// - parameter sourceView: The interested view.
    /// - parameter blocksTapOutsideCutoutPath: If true, only tappable inside cutoutPath and does not close by itself. Default: false
    public init(message: Message, nextButton: NextButton? = nil, sourceView: UIView, blocksTapOutsideCutoutPath: Bool = false) {
        if case .simple = nextButton, blocksTapOutsideCutoutPath {
            preconditionFailure("blocksTapOutsideCutoutPath must be false with simple NextButton.")
        }

        self.blocksTapOutsideCutoutPath = blocksTapOutsideCutoutPath
        self.message = message
        self.nextButton = nextButton
        self.sourceView = sourceView
    }
}
