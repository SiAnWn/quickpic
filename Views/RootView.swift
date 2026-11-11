import SwiftUI

/// 首页：列出 App 目录下的图片分类文件夹；可新建文件夹。
struct RootView: View {
    @EnvironmentObject private var store: PicStore
    @State private var showNew = false
    @State private var newName = ""

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        NavigationStack {
            Group {
                if store.folders.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.folders) { folder in
                                NavigationLink(value: folder) {
                                    folderCard(folder)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("QuickPic")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "folder.badge.plus")
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

    private func folderCard(_ folder: FolderInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.gradient.opacity(0.22))
                Image(systemName: "folder.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.accent)
            }
            .frame(height: 110)
            Text(folder.name)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
            Text("还没有图片文件夹")
                .font(.title3).bold()
            Text("点右上角「新建文件夹」创建分类，\n然后在「文件」App 里把图片放进对应文件夹。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { showNew = true } label: {
                Text("新建文件夹").padding(.horizontal, 10).padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
    }
}
