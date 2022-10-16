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

/// Making sure that it works inside childVC.
final class ChildViewController: UIViewController {

    private let manager = InstructionManager(overlayBackgroundColor: .overlayBackground)

    private let label1 = UIButton()
    private let label2 = UIButton()
    private let label3 = UIButton()
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

        configureLayout()
    }

    // MARK: Layout

    private func configureLayout() {

        view.backgroundColor = .background

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

        do {
            label3.backgroundColor = .systemYellow
            label3.setTitleColor(.systemBlue, for: .normal)
            label3.setTitle("Custom Next", for: .normal)
            label3.addTarget(self, action: #selector(tap3), for: .touchUpInside)
        }

        [label1, label2, label3].forEach {
            $0.widthAnchor.constraint(equalToConstant: 100).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 100).isActive = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview($0)
        }

        vStack.frame = CGRect(origin: originalVStackPoint, size: CGSize(width: 100, height: 300))
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

    // MARK: Invoking Yokoso Instructions

    private func show(_ instruction: Instruction, onFinish: ((Bool) -> ())? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self._show(instruction, onFinish: onFinish)
        }
    }

    private func _show(_ instruction: Instruction, onFinish: ((Bool) -> ())? = nil) {
        isShowingInstruction = true

        do {
            try manager.show(
                instruction,
                in: view
            ) { [weak self] success in
                guard let me = self else { return }

                me.isShowingInstruction = false
                onFinish?(success)
            }
        } catch {
            isShowingInstruction = false
            if let error = error as? InstructionError {
                showError(error)
            }
        }
    }

    private func showError(_ error: InstructionError) {

        let alert = UIAlertController(title: "Error", message: """
        \(error)
        You get this error when sourceView is not fully visible inside window bounds.
        Remember that same situation applys on window size changes(device rotation or iPad SplitView variants).
        NOTE: This error message is demonstration purpose.
        """, preferredStyle: .alert)

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

    @objc private func tap3() {
        print(#function)
        if !isShowingInstruction {
            startI3()
        }
    }

    private func startI1() {
        show(
            .init(
                message: .init(attributedString: makeMessage("Hi with simple Next button. Tap anywhere to continue."), backgroundColor: .background),
                nextButton: .simple("Next"),
                sourceView: label1
            )
        ) { [weak self] success in
            print("finish 1 \(success)")
            self?.startI2()
        }
    }

    private func startI2() {
        show(
            .init(
                message: .init(attributedString: makeMessage("You have to tap here to continue.\nTap again to restart these instructions."), backgroundColor: .background),
                sourceView: label2,
                blocksTapOutsideCutoutPath: true
            )
        ) { [weak self] success in
            print("finish 2 \(success)")
            self?.startI3()
        }
    }

    private func startI3() {
        show(
            .init(
                message: .init(attributedString: makeMessage("Bottom area is fully customizable.🍣"), backgroundColor: .background),
                nextButton: .custom(makeNextButtonView()),
                sourceView: label3
            )
        ) { success in
            print("finish 3 \(success)")
        }
    }

    // MARK: Custom Message and NextButton

    private func makeMessage(_ value: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: value)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        attr.addAttributes([
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 14),
        ], range: NSRangeFromString(value))
        return attr
    }

    private func makeNextButtonView() -> UIView {
        let hStack: UIStackView = {
            let hStack = UIStackView()
            hStack.axis = .horizontal
            hStack.distribution = .equalSpacing
            hStack.alignment = .center
            hStack.spacing = 0
            return hStack
        }()

        let progress = UILabel()
        progress.text = "🍣"
        let next = UIButton(type: .roundedRect)
        next.setTitle("Next", for: .normal)
        next.setTitleColor(.systemRed, for: .normal)
        let skip = UIButton(type: .roundedRect)
        skip.setTitle("Skip", for: .normal)

        next.addTarget(self, action: #selector(nextByCustomButton), for: .touchUpInside)
        skip.addTarget(self, action: #selector(skipByCustomButton), for: .touchUpInside)

        [next, progress, skip].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            hStack.addArrangedSubview($0)
        }

        return hStack
    }

    @objc private func nextByCustomButton() {
        manager.close()
    }

    @objc private func skipByCustomButton() {
        manager.close()
    }
}
