import SwiftUI

/// 全屏幻灯片：按所选方式(顺序/随机)、间隔、过渡自动播放，循环；可暂停/停止。
struct SlideshowView: View {
    @EnvironmentObject private var store: PicStore
    @Environment(\.dismiss) private var dismiss

    @State private var order: [Int] = []
    @State private var pos: Int = 0
    @State private var showUI = true
    @State private var paused = false

    private var taskID: String {
        "\(store.interval)-\(paused)-\(store.slideshowMode.rawValue)-\(store.transition.rawValue)"
    }

    private var trans: AnyTransition {
        switch store.transition {
        case .fade:  return .opacity
        case .slide: return .asymmetric(insert: .move(edge: .trailing), remove: .move(edge: .leading))
        case .zoom:  return .scale(scale: 1.08).combined(with: .opacity)
        case .none:  return .identity
        }
    }

    private var anim: Animation {
        switch store.transition {
        case .none: return .linear(duration: 0.01)
        default:    return .easeInOut(duration: 0.8)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let idx = order[safe: pos], let item = store.images[safe: idx] {
                AsyncThumb(url: item.url, maxPixel: 2200, contentMode: .fit)
                    .id(item.id)
                    .transition(trans)
                    .ignoresSafeArea()
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { showUI.toggle() } }
                .ignoresSafeArea()

            if showUI {
                VStack {
                    HStack {
                        circleButton("xmark") { dismiss() }
                        Spacer()
                        circleButton(paused ? "play.fill" : "pause.fill") { paused.toggle() }
                        Spacer()
                        Text("\(min(pos + 1, max(order.count, 1))) / \(order.count)")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.black.opacity(0.45), in: Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .clipped()
        .statusBarHidden(!showUI)
        .onAppear { if order.isEmpty { buildOrder() } }
        .task(id: taskID) {
            while !Task.isCancelled {
                if paused {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    continue
                }
                let secs = max(0.5, store.interval)
                try? await Task.sleep(nanoseconds: UInt64(secs * 1_000_000_000))
                if Task.isCancelled { break }
                advance()
            }
        }
    }

    private func circleButton(_ system: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.45), in: Circle())
        }
    }

    private func buildOrder() {
        let n = store.images.count
        guard n > 0 else { dismiss(); return }
        var idx = Array(0..<n)
        if store.slideshowMode == .random { idx.shuffle() }
        order = idx
        pos = 0
        warmAhead()
    }

    private func advance() {
        guard !order.isEmpty else { return }
        withAnimation(anim) {
            pos += 1
            if pos >= order.count {
                if store.slideshowMode == .random { buildOrder() } else { pos = 0 }
            }
        }
        warmAhead()
    }

    /// 预解码接下来 2 张写入缓存，切换时直接命中，过渡更顺、不闪。
    private func warmAhead() {
        let n = order.count
        guard n > 0 else { return }
        for k in 1...2 {
            let p = (pos + k) % n
            guard let idx = order[safe: p], let item = store.images[safe: idx] else { continue }
            warm(item.url)
        }
    }

    private func warm(_ url: URL) {
        if ThumbCache.shared.get(url, 2200) != nil { return }
        Task {
            let img = await Task.detached(priority: .utility) {
                PicLoader.image(url: url, maxPixel: 2200)
            }.value
            if let img { ThumbCache.shared.set(url, 2200, img) }
        }
    }
}
