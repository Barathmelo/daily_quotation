import SwiftUI
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var intensity: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: blurStyle)
        let view = UIVisualEffectView(effect: effect)
        view.alpha = intensity    // 控制透明程度（iOS 26 的关键）
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
