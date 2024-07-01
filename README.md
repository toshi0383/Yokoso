# 🌸Yokoso🗻

Yet another super simple spotlight instruction framework for UIKit iOS.

## Why Yokoso?

- [x] Supports device rotation / iPad SplitView
- [x] Closure style callback (no complex datasources or delegates)
- [x] Checks if interested view is inside window's bounds
- [x] Swift Concurrency
- [ ] Swift 6 Concurrency Check Mode ( work in progress )

## Requirements

- iOS 14+

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
) async throws
```

### Showing single Instruction

```swift
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
    )

} catch {
    if let error = error as? InstructionError {
        assertionFailure(error.localizedDescription)
    }
}
```

Please refer to the Example app for further customization.

## SwiftUI

You can use Yokoso for SwiftUI view, at least if you're embedding with `UIHostingController`.

First you need to retrieve interested view's frame via `ObservableObject` + `GeometryReader`.

```swift
class ViewModel: ObservableObject {
    @Published var interestedViewRect: CGRect?
}

struct YourView: View {
    @ObservedObject var viewModel: ViewModel
    var body: some View {
        GeometryReader { p in
            yourLayout
                .onAppear {
                    viewModel.interestedViewRect = p.frame(in: .global)
                }
        }
    }

}
```

Then pass that frame to `sourceRect` parameter of `InstructionManager.show`.

```swift
    try await instructionManager?.show(
        .init(
            message: .init(attributedString: message, backgroundColor: .v4.monotone8),
            nextButton: .custom(...),
            sourceView: view,
            sourceRect: sourceRect,
            blocksTapOutsideCutoutPath: true,
            ignoresTapInsideCutoutPath: true
        ),
        in: view
    )
```

## Install

- [x] Swift Package Manager

## Contributing

Any contributions are warmly welcomed.😊

- Feature Request / Pull Request
- Bug Report
- Question!

## LICENSE

MIT
