import UIKit

final class MessageLabel: UIView {

    let instruction: Instruction
    var onTapNext: (() -> ())?

    init(_ instruction: Instruction) {
        self.instruction = instruction

        super.init(frame: .zero)

        configureLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureLayout() {
        let message = instruction.message

        layer.cornerRadius = 5
        backgroundColor = message.backgroundColor

        let label = UILabel()
        label.attributedText = message.attributedString
        label.numberOfLines = 0

        let labelPadding: CGFloat = 15

        let vStack: UIStackView = {
            let vStack = UIStackView()
            vStack.axis = .vertical
            vStack.distribution = .fill
            vStack.alignment = .center
            vStack.spacing = 0
            return vStack
        }()

        [label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview($0)
        }

        let bottom: CGFloat = instruction.interactionStyle.needsNextButton ? 5 : labelPadding

        constrainSubview(vStack, top: labelPadding, bottom: bottom, leading: labelPadding, trailing: labelPadding)

        if case .nextButton(let nextText) = instruction.interactionStyle {
            let button = UIButton()
            button.setAttributedTitle(nextText, for: .normal)
            button.addTarget(self, action: #selector(tapNext), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(lessThanOrEqualToConstant: message.maxWidth),
        ])
    }

    @objc private func tapNext() {
        onTapNext?()
    }
}
