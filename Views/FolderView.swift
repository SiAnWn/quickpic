import SwiftUI

/// 某个分类文件夹：网格浏览图片；可打开幻灯片设置并开始播放。
struct FolderView: View {
    let mode: PicMode
    @EnvironmentObject private var store: PicStore

    @State private var selected: ImageItem? = nil
    @State private var showSlideshow = false
    @State private var showSettings = false

    private var folderName: String {
        switch mode {
        case .all: return "全部"
        case .favorites: return "收藏"
        case .folder(let f): return f.name
        }
    }
    private func load() {
        switch mode {
        case .all: store.openAll()
        case .favorites: store.openFavorites()
        case .folder(let f): store.openFolder(f)
        }
    }
    private func reload() {
        switch mode {
        case .all: store.openAll()
        case .favorites: store.openFavorites()
        case .folder: store.refreshCurrent()
        }
    }
    private var emptyTitle: String {
        switch mode {
        case .all: return "还没有任何图片"
        case .favorites: return "还没有收藏"
        case .folder: return "这个文件夹还没有图片"
        }
    }
    private var emptyBody: String {
        switch mode {
        case .all: return "先用「文件」App 往各子文件夹里放图片，\n回到这里下拉即可刷新。"
        case .favorites: return "看大图时点右上角 ♡ 收藏，\n收藏的图片会集中显示在这里。"
        case .folder(let f): return "用「文件」App 把图片放进「\(f.name)」，\n回到这里下拉即可刷新。"
        }
    }

    var body: some View {
        Group {
            if store.images.isEmpty {
                emptyText
            } else {
                GeometryReader { geo in
                    let cols = max(4, Int(geo.size.width / 64))
                    let spacing: CGFloat = 3
                    let pad: CGFloat = 3
                    let cw = (geo.size.width - pad * 2 - spacing * CGFloat(cols - 1)) / CGFloat(cols)
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cw), spacing: spacing), count: cols),
                                  spacing: spacing) {
                            ForEach(store.images) { item in
                                Button { selected = item } label: {
                                    AsyncThumb(url: item.url, maxPixel: 300, contentMode: .fill)
                                        .frame(width: cw, height: cw)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(pad)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(folderName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "slideshow")
                }
            }
        }
        .onAppear { load() }
        .refreshable { reload() }
        .fullScreenCover(item: $selected) { item in
            let idx = store.images.firstIndex(where: { $0.id == item.id }) ?? 0
            ImageViewer(startIndex: idx)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            SlideshowView().environmentObject(store)
        }
        .sheet(isPresented: $showSettings) { settingsSheet }
    }

    // MARK: 幻灯片设置

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("播放方式") {
                    Picker("方式", selection: $store.slideshowMode) {
                        ForEach(SlideshowMode.allCases) { m in Text(m.label).tag(m) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("每张停留") {
                    Picker("间隔", selection: $store.interval) {
                        ForEach(store.intervalChoices, id: \.self) { s in Text("\(Int(s)) 秒").tag(s) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("过渡效果") {
                    Picker("过渡", selection: $store.transition) {
                        ForEach(SlideTransition.allCases) { t in Text(t.label).tag(t) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Button {
                        showSettings = false
                        showSlideshow = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("开始幻灯片播放（\(store.images.count) 张）")
                        }
                    }
                    .disabled(store.images.isEmpty)
                }
            }
            .navigationTitle("幻灯片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = false } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var emptyText: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(store.theme.gradient.opacity(0.14)).frame(width: 96, height: 96)
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundStyle(store.theme.gradient)
            }
            Text(emptyTitle).font(.headline)
            Text(emptyBody)
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
