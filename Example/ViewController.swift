import Spotlight
import UIKit

final class ViewController: UIViewController {

    let child = ChildViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(child)
        view.addSubview(child.view)
        child.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        child.didMove(toParent: self)
    }
}

final class ChildViewController: UIViewController {

    private let manager = InstructionManager()

    private let label1 = UIButton()
    private let label2 = UIButton()
    private var isShowingInstruction = false

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            label1.setTitleColor(.systemRed, for: .normal)
            label1.setTitle("Hello", for: .normal)
            label1.backgroundColor = .systemGreen
            label1.addTarget(self, action: #selector(tap1), for: .touchUpInside)
        }
        do {
            label2.backgroundColor = .systemCyan
            label2.setTitleColor(.systemBlue, for: .normal)
            label2.setTitle("Tap", for: .normal)
            label2.addTarget(self, action: #selector(tap2), for: .touchUpInside)
        }

        let vStack: UIStackView = {
            let vStack = UIStackView()
            vStack.axis = .vertical
            vStack.distribution = .fill
            vStack.alignment = .fill
            vStack.spacing = 0
            return vStack
        }()

        [label1, label2].forEach {
            $0.widthAnchor.constraint(equalToConstant: 100).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 100).isActive = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview($0)
        }

        vStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }


    private func startI1() {
        isShowingInstruction = true

        manager.show(
            .init(
                style: .messageOnly,
                message: NSAttributedString(string: "Hi, this is Hello button. Tap anywhere to continue."),
                sourceView: label1
            ),
            in: view
        ) { [weak self] in
            guard let me = self else { return }

            me.startI2()
        }
    }

    private func startI2() {
        isShowingInstruction = true

        manager.show(
            .init(
                style: .blocksTapBesidesCutoutPath,
                message: NSAttributedString(string: "You have to tap here to continue. Tap again to restart these instructions."),
                sourceView: label2
            ),
            in: view
        ) { [weak self] in
            guard let me = self else { return }

            me.isShowingInstruction = false
        }
    }

    @objc private func tap1() {
        print(#function)
        if !isShowingInstruction {
            startI1()
        }
    }

    @objc private func tap2() {
        print(#function)
        if !isShowingInstruction {
            startI2()
        }
    }
}
