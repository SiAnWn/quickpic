import SwiftUI

/// 全屏查看器：横向滑动切换图片；顶部常驻「关闭 + 序号」。
/// 不在 TabView 上盖全屏手势层，否则会挡住左右滑动切换。
struct ImageViewer: View {
    @EnvironmentObject private var store: PicStore
    @Environment(\.dismiss) private var dismiss

    let startIndex: Int
    @State private var index: Int = 0

    var body: some View {
        let images = store.images
        ZStack(alignment: .top) {
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

                topBar(count: images.count)
            }
        }
        .onAppear { index = startIndex }
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
