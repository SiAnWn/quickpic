import SwiftUI

/// 首页：列出 App 目录下的图片分类文件夹（带封面）；可新建文件夹。
struct RootView: View {
    @EnvironmentObject private var store: PicStore
    @State private var showNew = false
    @State private var newName = ""

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        NavigationStack {
            Group {
                if store.folders.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(store.folders) { folder in
                                NavigationLink(value: folder) {
                                    folderCard(folder)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("QuickPic")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "folder.badge.plus")
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationDestination(for: FolderInfo.self) { folder in
                FolderView(folder: folder)
            }
            .onAppear { store.scanFolders() }
            .refreshable { store.scanFolders() }
            .alert("新建文件夹", isPresented: $showNew) {
                TextField("名称", text: $newName).autocorrectionDisabled()
                Button("创建") { store.createFolder(newName); newName = "" }
                Button("取消", role: .cancel) { newName = "" }
            } message: {
                Text("将在 QuickPic 的目录里创建一个子文件夹，之后用「文件」App 往里面放图片。")
            }
        }
    }

    // MARK: 文件夹卡片（封面 + 渐变遮罩 + 名称）

    private func folderCard(_ folder: FolderInfo) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06))

            if let cover = folder.coverURL {
                AsyncThumb(url: cover, maxPixel: 500, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Theme.gradient.opacity(0.28))
                    Image(systemName: "folder.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(height: 150)
            }

            LinearGradient(colors: [.clear, .black.opacity(0.72)],
                           startPoint: .center, endPoint: .bottom)

            Text(folder.name)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
                .padding(12)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
    }

    // MARK: 空状态

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Theme.gradient.opacity(0.16)).frame(width: 116, height: 116)
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.gradient)
            }
            Text("还没有图片文件夹")
                .font(.title2).bold()
            Text("点右上角「新建文件夹」创建分类，\n然后在「文件」App 里把图片放进对应文件夹。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { showNew = true } label: {
                Label("新建文件夹", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Theme.gradient, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
