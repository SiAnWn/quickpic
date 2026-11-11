import SwiftUI

/// 某个分类文件夹：网格浏览图片；可打开幻灯片设置并开始播放。
struct FolderView: View {
    let folder: FolderInfo
    @EnvironmentObject private var store: PicStore

    @State private var selected: ImageItem? = nil
    @State private var showSlideshow = false
    @State private var showSettings = false

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 3)]

    var body: some View {
        Group {
            if store.images.isEmpty {
                emptyText
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(store.images) { item in
                            Button { selected = item } label: {
                                AsyncThumb(url: item.url, maxPixel: 300)
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "slideshow")
                }
            }
        }
        .onAppear { store.openFolder(folder) }
        .refreshable { store.refreshCurrent() }
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
        VStack(spacing: 12) {
            Image(systemName: "photo.stack").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("这个文件夹还没有图片").foregroundStyle(.secondary)
            Text("用「文件」App 把图片放进「\(folder.name)」，下拉可刷新。")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(30)
    }
}
