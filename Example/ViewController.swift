import Yokoso
import UIKit

final class ViewController: UIViewController {

    private let manager = InstructionManager(overlayBackgroundColor: .overlayBackground)

    private var isShowingInstruction = false

    private let label1 = UIButton()
    private let label2 = UIButton()
    private let label3 = UIButton()
    private let label4 = UIButton()

    private let vStack: UIStackView = {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.distribution = .fill
        vStack.alignment = .leading
        vStack.spacing = 0
        return vStack
    }()

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureLayout()
    }

    // MARK: Invoking Yokoso Instructions

    private func show(_ instruction: Instruction, onFinish: ((Bool) -> ())? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self._show(instruction, onFinish: onFinish)
        }
    }

    private func _show(_ instruction: Instruction, onFinish: ((Bool) -> ())? = nil) {
        isShowingInstruction = true

        Task {
            do {
                try await manager.show(
                    instruction,
                    in: view
                )
            } catch {

                if let error = error as? InstructionError {
                    showError(error)
                }
            }
            isShowingInstruction = false
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
                message: .init(attributedString: makeMessage("You have to tap \"Next\" to continue.\nTap again to restart these instructions."), backgroundColor: .background),
                nextButton: .simple("Next"),
                sourceView: label2,
                blocksTapOutsideCutoutPath: true,
                ignoresTapInsideCutoutPath: true
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

    private func startI4() {
        show(
            .init(
                message: .init(attributedString: makeMessage("Highlight area is customizable by sourceRect.🍣"), backgroundColor: .background),
                nextButton: .custom(makeNextButtonView()),
                sourceView: label4,
                sourceRect: CGRect(x: 0, y: 0, width: 100, height: 100)
            )
        ) { success in
            print("finish 4 \(success)")
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

        do {
            label4.setTitleColor(.systemRed, for: .normal)
            label4.setTitle("sourceRect", for: .normal)
            label4.backgroundColor = .systemGreen
            label4.addTarget(self, action: #selector(tap4), for: .touchUpInside)
        }


        [label1, label2, label3].forEach {
            $0.widthAnchor.constraint(equalToConstant: 100).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 100).isActive = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview($0)
        }
        [label4].forEach {
            $0.widthAnchor.constraint(equalToConstant: 200).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 100).isActive = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview($0)
        }

        vStack.frame = CGRect(origin: originalVStackPoint, size: CGSize(width: 200, height: 400))
        vStack.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        view.addSubview(vStack)
    }

    // MARK: Handing Gesture

    private var originalVStackPoint: CGPoint = .init(x: 50, y: 50)

    @objc private func handlePan(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            originalVStackPoint = vStack.frame.origin
        }
        let t = panGesture.translation(in: view)
        let o = originalVStackPoint
        vStack.frame.origin = CGPoint(x: t.x + o.x, y: t.y + o.y)
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

    @objc private func tap4() {
        print(#function)
        if !isShowingInstruction {
            startI4()
        }
    }

    // MARK: Utilities

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
}

protocol InstructionManagerType: AnyObject {
}

extension InstructionManager: InstructionManagerType {}

@MainActor
final class MyViewModel: ObservableObject {
    // NOTE: Can be used as default argument of init, in case of dependency injection like this.
    init(manager: InstructionManagerType = InstructionManager()) {
    }
}
