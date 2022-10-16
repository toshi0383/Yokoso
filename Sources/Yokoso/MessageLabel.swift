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
            vStack.alignment = .fill
            vStack.spacing = 0
            return vStack
        }()

        [label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview($0)
        }

        let bottom: CGFloat = instruction.nextButton == nil ? labelPadding : 5

        constrainSubview(vStack, top: labelPadding, bottom: bottom, leading: labelPadding, trailing: labelPadding)

        if let nextButton = instruction.nextButton {
            switch nextButton {

            case .simple(let nextText):
                let button = UIButton(type: .system)
                button.setTitle(nextText, for: .normal)
                button.addTarget(self, action: #selector(tapNext), for: .touchUpInside)
                button.translatesAutoresizingMaskIntoConstraints = false
                vStack.addArrangedSubview(button)

            case .custom(let customView):
                customView.translatesAutoresizingMaskIntoConstraints = false
                vStack.addArrangedSubview(customView)
            }
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(lessThanOrEqualToConstant: message.maxWidth),
        ])
    }

    @objc private func tapNext() {
        onTapNext?()
    }
}
