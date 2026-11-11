import Foundation

/// 浏览目标：某个文件夹，或"全部"（汇总所有文件夹的图片）。
enum PicMode: Hashable {
    case all
    case favorites
    case folder(FolderInfo)
}
