import Yokoso
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

    private let vStack: UIStackView = {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.distribution = .fill
        vStack.alignment = .fill
        vStack.spacing = 0
        return vStack
    }()

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

        [label1, label2].forEach {
            $0.widthAnchor.constraint(equalToConstant: 100).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 100).isActive = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview($0)
        }

        vStack.frame = CGRect(origin: originalVStackPoint, size: CGSize(width: 100, height: 200))
        vStack.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        view.addSubview(vStack)
    }

    private var originalVStackPoint: CGPoint = .init(x: 50, y: 50)

    @objc private func handlePan(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            originalVStackPoint = vStack.frame.origin
        }
        let t = panGesture.translation(in: view)
        let o = originalVStackPoint
        vStack.frame.origin = CGPoint(x: t.x + o.x, y: t.y + o.y)
    }

    private var nextButtonAttributedString: NSAttributedString {
        let attr = NSMutableAttributedString(string: "Next")
        attr.addAttributes([
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.systemRed,
        ], range: NSRange(location: 0, length: attr.string.count))
        return attr
    }

    private func startI1() {
        show(
            .init(
                style: .nextButton(nextButtonAttributedString),
                message: .init(attributedString: NSAttributedString(string: "Hi, this is Hello button. Tap anywhere to continue."), backgroundColor: .white),
                sourceView: label1
            )
        ) { [weak self] in
            self?.startI2()
        }
    }

    private func startI2() {
        show(
            .init(
                style: .blocksTapOutsideCutoutPath,
                message: .init(attributedString: NSAttributedString(string: "You have to tap here to continue.\nTap again to restart these instructions."), backgroundColor: .white),
                sourceView: label2
            )
        )
    }

    private func show(_ instruction: Instruction, onFinish: (() -> ())? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self._show(instruction, onFinish: onFinish)
        }
    }

    private func _show(_ instruction: Instruction, onFinish: (() -> ())? = nil) {
        isShowingInstruction = true

        do {
            try manager.show(
                instruction,
                in: view
            ) { [weak self] in
                guard let me = self else { return }

                me.isShowingInstruction = false
                onFinish?()
            }
        } catch {
            isShowingInstruction = false
            if let error = error as? InstructionError {
                showError(error)
            }
        }
    }

    private func showError(_ error: InstructionError) {
        let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
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
