import SwiftUI

/// 全屏查看器：横向滑动切换图片；点按显示/隐藏顶栏（关闭 + 序号）。
struct ImageViewer: View {
    @EnvironmentObject private var store: PicStore
    @Environment(\.dismiss) private var dismiss

    let startIndex: Int
    @State private var index: Int = 0
    @State private var showUI = true

    var body: some View {
        let images = store.images
        ZStack {
            Color.black.ignoresSafeArea()

            if images.isEmpty {
                Text("没有图片").foregroundStyle(.secondary)
            } else {
                TabView(selection: $index) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { i, item in
                        AsyncThumb(url: item.url, maxPixel: 2200, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                // 点按切换界面（只接单击，不消费左右滑动，翻页照常）
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { showUI.toggle() }
                    }
                    .ignoresSafeArea()

                if showUI {
                    topBar(count: images.count)
                        .transition(.opacity)
                }
            }
        }
        .statusBarHidden(!showUI)
        .onAppear { index = startIndex }
    }

    private func topBar(count: Int) -> some View {
        VStack {
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
            Spacer()
        }
    }
}
