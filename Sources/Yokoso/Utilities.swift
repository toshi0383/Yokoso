import UIKit

extension NSLayoutConstraint {
    func priority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

extension UIView {
    enum Edge {
        case top, bottom, leading, trailing
    }

    /// subviewを四隅に貼り付ける。
    func constrainSubview(
        _ view: UIView,
        top: CGFloat = 0,
        bottom: CGFloat = 0,
        leading: CGFloat = 0,
        trailing: CGFloat = 0,
        againstSafeAreaOf edges: Set<Edge> = []
    ) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(
                equalTo: edges.contains(.top) ? safeAreaLayoutGuide.topAnchor : topAnchor,
                constant: top
            ),
            view.bottomAnchor.constraint(
                equalTo: edges.contains(.bottom) ? safeAreaLayoutGuide.bottomAnchor : bottomAnchor,
                constant: -bottom
            ),
            view.leadingAnchor.constraint(
                equalTo: edges.contains(.leading) ? safeAreaLayoutGuide.leadingAnchor : leadingAnchor,
                constant: leading
            ),
            view.trailingAnchor.constraint(
                equalTo: edges.contains(.trailing) ? safeAreaLayoutGuide.trailingAnchor : trailingAnchor,
                constant: -trailing
            ),
        ])

    }

    /// subviewを四隅に貼り付ける。
    func constrainSubview(
        _ view: UIView,
        horizontal: CGFloat = 0,
        vertical: CGFloat = 0,
        againstSafeAreaOf edges: Set<Edge> = []
    ) {
        constrainSubview(
            view,
            top: vertical,
            bottom: vertical,
            leading: horizontal,
            trailing: horizontal,
            againstSafeAreaOf: edges
        )
    }

    func centerSubview(_ view: UIView) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}

extension CGRect {
    mutating func expand(_ edgeInsets: UIEdgeInsets) {
        self = CGRect(
            x: minX - edgeInsets.left,
            y: minY - edgeInsets.top,
            width: width + edgeInsets.left + edgeInsets.right,
            height: height + edgeInsets.top + edgeInsets.bottom
        )
    }
}
