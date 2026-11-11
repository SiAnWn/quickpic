import SwiftUI
import Foundation
import UniformTypeIdentifiers

enum SlideshowMode: String, CaseIterable, Identifiable {
    case sequential
    case random
    var id: String { rawValue }
    var label: String { self == .sequential ? "顺序播放" : "随机播放" }
}

enum SlideTransition: String, CaseIterable, Identifiable {
    case fade
    case slide
    case zoom
    case none
    var id: String { rawValue }
    var label: String {
        switch self {
        case .fade: return "淡入淡出"
        case .slide: return "左右滑动"
        case .zoom: return "缩放淡入"
        case .none: return "直接切换"
        }
    }
}

/// 图片库：只读写 App 自己的 Documents 目录。列出其中的子文件夹作为分类，
/// 进入某个文件夹列出其中的图片。幻灯片方式/间隔持久化。
final class PicStore: ObservableObject {
    @Published var folders: [FolderInfo] = []
    @Published var images: [ImageItem] = []
    @Published var currentFolder: FolderInfo? = nil

    @Published var slideshowMode: SlideshowMode = .random { didSet { saveSettings() } }
    @Published var interval: Double = 3.0 { didSet { saveSettings() } }
    @Published var transition: SlideTransition = .fade { didSet { saveSettings() } }

    let intervalChoices: [Double] = [1, 2, 3, 5, 8]

    private let fm = FileManager.default
    private let imageExts: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "webp", "gif", "bmp", "tiff", "tif"]

    var documentsURL: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // MARK: 设置持久化

    private var settingsURL: URL {
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("quickpic.json")
    }

    private struct Settings: Codable { var mode: String; var interval: Double; var transition: String }

    init() { loadSettings() }

    private func loadSettings() {
        if let data = try? Data(contentsOf: settingsURL),
           let s = try? JSONDecoder().decode(Settings.self, from: data) {
            slideshowMode = SlideshowMode(rawValue: s.mode) ?? .random
            if intervalChoices.contains(s.interval) { interval = s.interval }
            transition = SlideTransition(rawValue: s.transition) ?? .fade
        }
    }

    private func saveSettings() {
        let s = Settings(mode: slideshowMode.rawValue, interval: interval, transition: transition.rawValue)
        if let data = try? JSONEncoder().encode(s) { try? data.write(to: settingsURL) }
    }

    // MARK: 图片识别

    private func isImage(_ url: URL, contentType: UTType?) -> Bool {
        if let ct = contentType, ct.conforms(to: .image) { return true }
        return imageExts.contains(url.pathExtension.lowercased())
    }

    /// 首次启动写一个说明文件，逼出 App 的"文件"目录。
    func ensureDocuments() {
        let readme = documentsURL.appendingPathComponent("把图片放进子文件夹.txt")
        if !fm.fileExists(atPath: readme.path) {
            let text = "用法：在「文件」App 里进入 QuickPic 文件夹，新建子文件夹（如 风景、人物），把图片放进去；"
                + "或在本 App 里点右上角「新建文件夹」。\n"
            try? text.write(to: readme, atomically: true, encoding: .utf8)
        }
    }

    // MARK: 文件夹

    func scanFolders() {
        ensureDocuments()
        let keys: [URLResourceKey] = [.isDirectoryKey]
        var result: [FolderInfo] = []
        if let items = try? fm.contentsOfDirectory(at: documentsURL,
                                                  includingPropertiesForKeys: keys,
                                                  options: [.skipsHiddenFiles]) {
            for url in items where (try? url.resourceValues(forKeys: Set(keys)))?.isDirectory == true {
                result.append(FolderInfo(url: url, name: url.lastPathComponent,
                                         coverURL: firstImageURL(in: url)))
            }
        }
        result.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        folders = result
    }

    /// 文件夹里第一张图片（按名称排序），用作封面。
    private func firstImageURL(in dir: URL) -> URL? {
        let keys: [URLResourceKey] = [.contentTypeKey, .isRegularFileKey]
        guard let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys,
                                                     options: [.skipsHiddenFiles]) else { return nil }
        var imgs: [URL] = []
        for url in items {
            let v = try? url.resourceValues(forKeys: Set(keys))
            if v?.isRegularFile == true, isImage(url, contentType: v?.contentType) { imgs.append(url) }
        }
        imgs.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        return imgs.first
    }

    func createFolder(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let url = documentsURL.appendingPathComponent(trimmed)
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        scanFolders()
    }

    func openFolder(_ folder: FolderInfo) {
        currentFolder = folder
        scanImages(in: folder.url)
    }

    func scanImages(in dir: URL) {
        let keys: [URLResourceKey] = [.contentTypeKey, .isRegularFileKey]
        var result: [ImageItem] = []
        if let items = try? fm.contentsOfDirectory(at: dir,
                                                  includingPropertiesForKeys: keys,
                                                  options: [.skipsHiddenFiles]) {
            for url in items {
                let v = try? url.resourceValues(forKeys: Set(keys))
                guard v?.isRegularFile == true else { continue }
                if isImage(url, contentType: v?.contentType) {
                    result.append(ImageItem(url: url, name: url.deletingPathExtension().lastPathComponent))
                }
            }
        }
        result.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        images = result
    }

    func refreshCurrent() {
        if let f = currentFolder { scanImages(in: f.url) } else { scanFolders() }
    }
}
