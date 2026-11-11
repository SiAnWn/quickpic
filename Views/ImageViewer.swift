import SwiftUI

/// 全屏查看器：单个可缩放视图复用（切换只换图 + 淡入淡出，不重建），
/// 支持双指缩放 / 双击放大；左右滑切换、单击显示/隐藏界面。
/// 顶栏含关闭 / 序号 / 收藏。只解码当前及附近，几万张也稳。
struct ImageViewer: View {
    @EnvironmentObject private var store: PicStore
    @Environment(\.dismiss) private var dismiss

    let startIndex: Int
    @State private var index: Int = 0
    @State private var showUI = false
    @State private var display: UIImage?

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
                                      onSingleTap: { withAnimation(.easeOut(duration: 0.2)) { showUI.toggle() } })
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
            if let item = images[safe: index] {
                Button { store.toggleFavorite(item.id) } label: {
                    Image(systemName: store.isFavorite(item.id) ? "heart.fill" : "heart")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(store.isFavorite(item.id) ? Color(red: 0.98, green: 0.29, blue: 0.55) : .white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.45), in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}
