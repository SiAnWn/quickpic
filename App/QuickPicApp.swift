import SwiftUI
import UIKit

@main
struct QuickPicApp: App {
    @StateObject private var store = PicStore()

    init() {
        // 看图/幻灯片时保持屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}
