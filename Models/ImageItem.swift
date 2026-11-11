import Foundation

/// 一张图片（App 自己目录里的文件）。
struct ImageItem: Identifiable, Hashable {
    let url: URL
    let name: String
    var id: String { url.path }
}

/// 一个图片分类文件夹（App Documents 下的子目录）。
struct FolderInfo: Identifiable, Hashable {
    let url: URL
    let name: String
    var id: String { url.path }
}
