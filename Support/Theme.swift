import SwiftUI

/// 内置主题：每套定义强调色、按钮/图标渐变、以及主页背景渐变（深色版，保证白字清晰）。
enum AppTheme: String, CaseIterable, Identifiable {
    case bluePink
    case bluePurple
    case tealGreen
    case sunset
    case purplePink
    case graphite

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bluePink:   return "蓝粉"
        case .bluePurple: return "蓝紫"
        case .tealGreen:  return "青绿"
        case .sunset:     return "落日"
        case .purplePink: return "紫粉"
        case .graphite:   return "石墨"
        }
        }

    private var c1: Color {
        switch self {
        case .bluePink:   return Color(red: 0.15, green: 0.55, blue: 0.98)
        case .bluePurple: return Color(red: 0.23, green: 0.42, blue: 0.96)
        case .tealGreen:  return Color(red: 0.07, green: 0.70, blue: 0.60)
        case .sunset:     return Color(red: 1.00, green: 0.48, blue: 0.18)
        case .purplePink: return Color(red: 0.55, green: 0.23, blue: 0.94)
        case .graphite:   return Color(red: 0.42, green: 0.45, blue: 0.50)
        }
    }
    private var c2: Color {
        switch self {
        case .bluePink:   return Color(red: 0.98, green: 0.29, blue: 0.55)
        case .bluePurple: return Color(red: 0.55, green: 0.23, blue: 0.94)
        case .tealGreen:  return Color(red: 0.37, green: 0.79, blue: 0.25)
        case .sunset:     return Color(red: 0.95, green: 0.23, blue: 0.43)
        case .purplePink: return Color(red: 0.96, green: 0.30, blue: 0.60)
        case .graphite:   return Color(red: 0.23, green: 0.25, blue: 0.28)
        }
    }
    private var bg1: Color {
        switch self {
        case .bluePink:   return Color(red: 0.08, green: 0.13, blue: 0.34)
        case .bluePurple: return Color(red: 0.08, green: 0.12, blue: 0.30)
        case .tealGreen:  return Color(red: 0.03, green: 0.20, blue: 0.18)
        case .sunset:     return Color(red: 0.30, green: 0.10, blue: 0.05)
        case .purplePink: return Color(red: 0.18, green: 0.08, blue: 0.30)
        case .graphite:   return Color(red: 0.10, green: 0.11, blue: 0.13)
        }
    }
    private var bg2: Color {
        switch self {
        case .bluePink:   return Color(red: 0.34, green: 0.08, blue: 0.24)
        case .bluePurple: return Color(red: 0.20, green: 0.08, blue: 0.32)
        case .tealGreen:  return Color(red: 0.06, green: 0.22, blue: 0.10)
        case .sunset:     return Color(red: 0.30, green: 0.06, blue: 0.14)
        case .purplePink: return Color(red: 0.30, green: 0.08, blue: 0.20)
        case .graphite:   return Color(red: 0.05, green: 0.05, blue: 0.06)
        }
    }

    var accent: Color { c1 }

    var gradient: LinearGradient {
        LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [bg1, bg2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
