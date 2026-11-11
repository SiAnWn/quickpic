import SwiftUI

/// 在 iOS 26 上给视图加「液态玻璃」；更早系统回退到给定的背景样式（保证旧设备照常显示）。
struct GlassOrBackground<S: Shape, F: ShapeStyle>: ViewModifier {
    let shape: S
    let fallback: F

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(fallback, in: shape)
        }
    }
}

extension View {
    func glassOr<S: Shape, F: ShapeStyle>(in shape: S, fallback: F) -> some View {
        modifier(GlassOrBackground(shape: shape, fallback: fallback))
    }
}
