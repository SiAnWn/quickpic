import UIKit

/// 缩略图磁盘缓存：解码过的缩略图存到 Caches，重开文件夹/重启 App 直接读，不再重复解码。
/// key 含文件修改时间，图片被替换后自动失效。
enum DiskThumb {
    private static let dir: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("qpthumbs", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()

    private static func hash(_ s: String) -> String {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return String(format: "%016llx", h)
    }

    static func key(_ url: URL, _ maxPixel: Int) -> String {
        let mtime = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate?.timeIntervalSince1970 ?? 0
        return hash("\(url.path)|\(maxPixel)|\(Int(mtime))")
    }

    static func load(_ key: String) -> UIImage? {
        UIImage(contentsOfFile: dir.appendingPathComponent(key + ".jpg").path)
    }

    static func save(_ image: UIImage, _ key: String) {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        try? data.write(to: dir.appendingPathComponent(key + ".jpg"))
    }
}
