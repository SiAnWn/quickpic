import SwiftUI
import UIKit
import ImageIO

/// 用 ImageIO 高效解码缩略图（大图只解码到指定像素，省内存）。
enum PicLoader {
    static func image(url: URL, maxPixel: Int) -> UIImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// 主线程缩略图缓存。
@MainActor
final class ThumbCache {
    static let shared = ThumbCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 400 }

    func get(_ url: URL, _ maxPixel: Int) -> UIImage? {
        cache.object(forKey: "\(url.path)|\(maxPixel)" as NSString)
    }
    func set(_ url: URL, _ maxPixel: Int, _ image: UIImage) {
        cache.setObject(image, forKey: "\(url.path)|\(maxPixel)" as NSString)
    }
}

/// 预热一张图（内存→磁盘→解码），供查看器/幻灯片提前加载相邻图。
@MainActor
func warmImage(_ url: URL, maxPixel: Int) {
    if ThumbCache.shared.get(url, maxPixel) != nil { return }
    Task.detached(priority: .utility) {
        let k = DiskThumb.key(url, maxPixel)
        if let d = DiskThumb.load(k) {
            await MainActor.run { ThumbCache.shared.set(url, maxPixel, d) }
            return
        }
        if let img = PicLoader.image(url: url, maxPixel: maxPixel) {
            DiskThumb.save(img, k)
            await MainActor.run { ThumbCache.shared.set(url, maxPixel, img) }
        }
    }
}

/// 加载一张完整图（内存→磁盘→解码），返回 UIImage。
@MainActor
func loadFull(_ url: URL, maxPixel: Int = 2200) async -> UIImage? {
    if let c = ThumbCache.shared.get(url, maxPixel) { return c }
    let img = await Task.detached(priority: .userInitiated) { () -> UIImage? in
        let k = DiskThumb.key(url, maxPixel)
        if let d = DiskThumb.load(k) { return d }
        if let decoded = PicLoader.image(url: url, maxPixel: maxPixel) {
            DiskThumb.save(decoded, k)
            return decoded
        }
        return nil
    }.value
    if let img { ThumbCache.shared.set(url, maxPixel, img) }
    return img
}

/// 异步加载并显示一张图片（网格用 .fill 裁切填充，全屏用 .fit 完整显示）。
struct AsyncThumb: View {
    let url: URL
    var maxPixel: Int = 400
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.white.opacity(0.05)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.medium)
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .clipped()
        .task(id: "\(url.path)|\(maxPixel)") {
            let u = url, mp = maxPixel
            if let hit = ThumbCache.shared.get(u, mp) { image = hit; return }
            let img = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                let k = DiskThumb.key(u, mp)
                if let d = DiskThumb.load(k) { return d }
                if let decoded = PicLoader.image(url: u, maxPixel: mp) {
                    DiskThumb.save(decoded, k)
                    return decoded
                }
                return nil
            }.value
            if let img {
                ThumbCache.shared.set(u, mp, img)
                image = img
            }
        }
    }
}
