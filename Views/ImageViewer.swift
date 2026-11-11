import SwiftUI

/// 全屏查看器：手动滑动的"窗口式"翻页——任意时刻只解码当前及附近各一张，
/// 因此几万张也流畅、内存恒定。左右滑切换；单击显示/隐藏顶栏（关闭 + 序号）。
struct ImageViewer: View {
    @EnvironmentObject private var store: PicStore
    @Environment(\.dismiss) private var dismiss

    let startIndex: Int
    @State private var index: Int = 0
    @State private var showUI = false
    @State private var goingNext = true

    private var images: [ImageItem] { store.images }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            if images.isEmpty {
                Text("没有图片").foregroundStyle(.secondary)
            } else {
                if let item = images[safe: index] {
                    AsyncThumb(url: item.url, maxPixel: 2200, contentMode: .fit)
                        .id(item.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: goingNext ? .trailing : .leading),
                            removal: .move(edge: goingNext ? .leading : .trailing)))
                        .ignoresSafeArea()
                }

                // 手势层：左右滑切换、单击显示/隐藏界面（无 TabView，不受数量限制）
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { showUI.toggle() }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { v in
                                let t = v.translation.width
                                if t < -60 { go(1) } else if t > 60 { go(-1) }
                            }
                    )
                    .ignoresSafeArea()

                if showUI {
                    topBar(count: images.count)
                        .transition(.opacity)
                }
            }
        }
        .clipped()
        .statusBarHidden(true)
        .onAppear {
            index = min(max(startIndex, 0), max(images.count - 1, 0))
            warm()
        }
    }

    private func go(_ dir: Int) {
        let new = index + dir
        guard new >= 0, new < images.count else { return }
        goingNext = dir > 0
        withAnimation(.easeOut(duration: 0.28)) { index = new }
        warm()
    }

    /// 预热当前前后各一张，滑动时即时显示、不闪。
    private func warm() {
        for d in [-1, 1] {
            guard let it = images[safe: index + d] else { continue }
            let u = it.url
            if ThumbCache.shared.get(u, 2200) != nil { continue }
            Task {
                let img = await Task.detached(priority: .utility) {
                    PicLoader.image(url: u, maxPixel: 2200)
                }.value
                if let img { ThumbCache.shared.set(u, 2200, img) }
            }
        }
    }

    private func topBar(count: Int) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.45), in: Circle())
            }
            Spacer()
            Text("\(min(index + 1, count)) / \(count)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.black.opacity(0.45), in: Capsule())
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}
