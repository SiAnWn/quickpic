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
            let img = await Task.detached(priority: .userInitiated) {
                PicLoader.image(url: u, maxPixel: mp)
            }.value
            if let img {
                ThumbCache.shared.set(u, mp, img)
                image = img
            }
        }
    }
}
