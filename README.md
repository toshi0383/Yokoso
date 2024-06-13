# 🌸Yokoso🗻

Yet another super simple spotlight instruction framework for UIKit iOS.

## Why Yokoso?

- [x] Supports device rotation / iPad SplitView
- [x] Closure style callback (no complex datasources or delegates)
- [x] Checks if interested view is inside window's bounds
- [x] Stateless ( manage by yourself )

## Screenshot

https://user-images.githubusercontent.com/6007952/197309254-e7a0ed85-89c0-4d5a-a022-6e02c1fadb3b.mp4

## How to use

It's super simple.
Import the module,

```swift
import Yokoso
```

initialize `InstructionManager`,

```swift
let manager = InstructionManager(overlayBackgroundColor: .overlayBackground)
```

then use `InstructionManager`'s interface to show or close your `Instruction`.

```swift
/// - throws: `InstructionError.interestedViewOutOfBounds`
public func show(
    _ instruction: Instruction,
    in view: UIView,
    onFinish: @escaping (Bool) -> ()
) throws
```

### Showing single Instruction

To simplify internal implementation, we don't check view state internally, but just redrawing everything again.
So make sure you know `isShowingInstruction` state to avoid calling `show()` multiple time.
It's safe to invoke `show` while showing, but it would trigger overlay's fade animation again.

```swift
if isShowingInstruction { return }

isShowingInstruction = true

do {

    try instructionManager.show(
        .init(
            message: .init(
                attributedString: attributedString,
                backgroundColor: uicolor
            ),
            nextButton: .simple("Next"),
            sourceView: label
        ),
        in: view
    ) { [weak self] success in
        guard let me = self else { return }

        // called when instruction "did" finish

        me.isShowingInstruction = false
    }

} catch {

    isShowingInstruction = false

    if let error = error as? InstructionError {
        showError(error)
    }
}
```

### Showing multiple Instructions

Yokoso is stateless.
If you want to show multiple instructions in order, then call `show()` in order.
This way you have more control over the timings, comparing to passing multiple `Instruction` at once.

```swift
private func startI1() {
    show(
        .init(
            message: .init(attributedString: makeMessage("Hi with simple Next button. Tap anywhere to continue."), backgroundColor: .background),
            nextButton: .simple("Next"),
            sourceView: label1
        )
    ) { [weak self] success in

        self?.startI2() // NOTE: Starting next instruction.

    }
}

private func startI2() {
    show(
        .init(
        ...
```

Please refer to example app inside repository for further customization.

## Install

- [x] Swift Package Manager

## Contributing

Any contributions are warmly welcomed.😊

- Feature Request / Pull Request
- Bug Report
- Question!

## LICENSE

MIT
