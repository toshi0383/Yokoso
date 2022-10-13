import UIKit

final class MessageLabel: UIView {

    let message: Instruction.Message

    init(_ message: Instruction.Message) {
        self.message = message

        super.init(frame: .zero)

        configureLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureLayout() {

        layer.cornerRadius = 5
        backgroundColor = message.backgroundColor

        let label = UILabel()
        label.attributedText = message.attributedString
        label.numberOfLines = 0

        let labelPadding: CGFloat = 15

        constrainSubview(label, horizontal: labelPadding, vertical: labelPadding)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(lessThanOrEqualToConstant: message.maxWidth),
        ])
    }
}
