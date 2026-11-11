import SwiftUI

/// 极简主题：蓝→粉强调色（与 SlidePlay 一致的观感）。
enum Theme {
    static let accent = Color(red: 0.15, green: 0.55, blue: 0.98)
    static let heart = Color(red: 0.98, green: 0.29, blue: 0.55)

    static let gradient = LinearGradient(
        colors: [Color(red: 0.15, green: 0.55, blue: 0.98),
                 Color(red: 0.98, green: 0.29, blue: 0.55)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 主页背景：偏深的蓝→粉渐变（保证白字与卡片清晰）。
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.13, green: 0.20, blue: 0.55),
                 Color(red: 0.34, green: 0.10, blue: 0.40),
                 Color(red: 0.62, green: 0.13, blue: 0.38)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}
