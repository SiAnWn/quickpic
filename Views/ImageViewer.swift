import SwiftUI

/// 全屏查看器：复用单个可缩放视图（切换只换图 + 淡入淡出，流畅且省内存）。
/// 双指/双击缩放；左右滑切换；下滑退出；单击显示序号；长按收藏（可撤销）。
/// 浏览到收藏图时右上角显示轻度心形特效。
struct ImageViewer: View {
    @EnvironmentObject private var store: PicStore
    @Environment(\.dismiss) private var dismiss

    let startIndex: Int
    @State private var index: Int = 0
    @State private var showUI = false
    @State private var display: UIImage?
    @State private var toast: String?
    @State private var toastUndo: (() -> Void)?
    @State private var toastGen = 0

    private var images: [ImageItem] { store.images }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            if images.isEmpty {
                Text("没有图片").foregroundStyle(.secondary)
            } else {
                if let display {
                    ZoomableImageView(image: display,
                                      onSwipe: { go($0) },
                                      onSingleTap: { withAnimation(.easeOut(duration: 0.2)) { showUI.toggle() } },
                                      onLongPress: { toggleFavorite() },
                                      onSwipeDown: { dismiss() })
                        .ignoresSafeArea()
                } else if let item = images[safe: index] {
                    AsyncThumb(url: item.url, maxPixel: 2200, contentMode: .fit)
                        .ignoresSafeArea()
                }

                if showUI {
                    topBar(count: images.count)
                        .transition(.opacity)
                }
            }
        }
        .statusBarHidden(true)
        .overlay(alignment: .bottomTrailing) {
            // 收藏特效（轻度）
            if let item = images[safe: index], store.isFavorite(item.id) {
                FavBadge()
                    .id(item.id)
                    .padding(.trailing, 16)
                    .padding(.bottom, 24)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                HStack(spacing: 12) {
                    Text(toast).foregroundStyle(.white)
                    Button("撤销") { toastUndo?(); hideToast() }
                        .foregroundStyle(store.theme.accent)
                }
                .font(.callout)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .glassOr(in: Capsule(), fallback: Color.black.opacity(0.72))
                .padding(.bottom, 40)
                .transition(.opacity)
            }
        }
        .onAppear {
            index = min(max(startIndex, 0), max(images.count - 1, 0))
        }
        .task(id: index) {
            guard let item = images[safe: index] else { return }
            if let img = await loadFull(item.url) { display = img }
            warm()
        }
    }

    private func go(_ dir: Int) {
        let new = index + dir
        guard new >= 0, new < images.count else { return }
        index = new
    }

    private func warm() {
        for d in [-1, 1] {
            if let it = images[safe: index + d] { warmImage(it.url, maxPixel: 2200) }
        }
    }

    private func toggleFavorite() {
        guard let item = images[safe: index] else { return }
        let was = store.isFavorite(item.id)
        store.toggleFavorite(item.id)
        showToast(was ? "已取消收藏" : "已收藏", undo: { store.toggleFavorite(item.id) })
    }

    private func showToast(_ text: String, undo: @escaping () -> Void) {
        toastGen += 1
        let my = toastGen
        withAnimation(.easeOut(duration: 0.2)) { toast = text; toastUndo = undo }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                if my == toastGen {
                    withAnimation(.easeIn(duration: 0.2)) { toast = nil; toastUndo = nil }
                }
            }
        }
    }

    private func hideToast() {
        toastGen += 1
        withAnimation(.easeIn(duration: 0.15)) { toast = nil; toastUndo = nil }
    }

    private func topBar(count: Int) -> some View {
        HStack {
            Spacer()
            Text("\(min(index + 1, count)) / \(count)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .glassOr(in: Capsule(), fallback: Color.black.opacity(0.45))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}
