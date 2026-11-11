import SwiftUI

/// 极简主题：蓝→粉强调色（与 SlidePlay 一致的观感）。
enum Theme {
    static let accent = Color(red: 0.15, green: 0.55, blue: 0.98)
    static let heart = Color(red: 0.98, green: 0.29, blue: 0.55)

    static let gradient = LinearGradient(
        colors: [Color(red: 0.15, green: 0.55, blue: 0.98),
                 Color(red: 0.98, green: 0.29, blue: 0.55)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}
