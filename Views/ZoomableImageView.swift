import SwiftUI
import UIKit

/// 可缩放图片视图（UIScrollView）：
/// - 双指缩放；放大后可拖动查看；双击在 1× 与 2.5× 间切换；
/// - 未缩放时左右滑 → onSwipe(±1) 切换图片；
/// - 单击 → onSingleTap（显示/隐藏界面）。
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    var onSwipe: (Int) -> Void
    var onSingleTap: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .black
        sv.minimumZoomScale = 1
        sv.maximumZoomScale = 4
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.isScrollEnabled = false          // 1× 时不平移，滑动用于切换；放大后由 didZoom 打开
        sv.delegate = context.coordinator

        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        iv.frame = sv.bounds
        sv.addSubview(iv)
        context.coordinator.imageView = iv

        let single = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.onSingleTap))
        let double = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.onDoubleTap(_:)))
        double.numberOfTapsRequired = 2
        single.require(toFail: double)
        sv.addGestureRecognizer(single)
        sv.addGestureRecognizer(double)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.onPan(_:)))
        pan.delegate = context.coordinator
        sv.addGestureRecognizer(pan)
        context.coordinator.pan = pan

        return sv
    }

    func updateUIView(_ sv: UIScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.imageView?.image = image
    }

    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: ZoomableImageView
        weak var imageView: UIImageView?
        weak var pan: UIPanGestureRecognizer?

        init(_ parent: ZoomableImageView) { self.parent = parent }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.isScrollEnabled = scrollView.zoomScale > 1.01
        }

        @objc func onSingleTap() { parent.onSingleTap() }

        @objc func onDoubleTap(_ g: UITapGestureRecognizer) {
            guard let sv = g.view as? UIScrollView else { return }
            if sv.zoomScale > 1.01 {
                sv.setZoomScale(1, animated: true)
            } else {
                let p = g.location(in: sv)
                let scale: CGFloat = 2.5
                let w = sv.bounds.width / scale, h = sv.bounds.height / scale
                sv.zoom(to: CGRect(x: p.x - w / 2, y: p.y - h / 2, width: w, height: h), animated: true)
            }
        }

        @objc func onPan(_ g: UIPanGestureRecognizer) {
            guard g.state == .ended else { return }
            let t = g.translation(in: g.view)
            if t.x < -60 { parent.onSwipe(1) }
            else if t.x > 60 { parent.onSwipe(-1) }
        }

        // 只在"未缩放 + 横向为主"时接管滑动；放大后交回 scrollView 平移
        func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
            guard gr === pan else { return true }
            guard let p = gr as? UIPanGestureRecognizer, let sv = p.view as? UIScrollView else { return false }
            if sv.zoomScale > 1.01 { return false }
            let v = p.velocity(in: sv)
            return abs(v.x) > abs(v.y) * 1.2
        }
    }
}

/// 一页可缩放图片：自行异步加载（命中缓存即时显示），加载前用占位图。
struct ZoomablePage: View {
    let item: ImageItem
    var onSwipe: (Int) -> Void
    var onSingleTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black
            if let image {
                ZoomableImageView(image: image, onSwipe: onSwipe, onSingleTap: onSingleTap)
                    .ignoresSafeArea()
            } else {
                AsyncThumb(url: item.url, maxPixel: 2200, contentMode: .fit)
                    .ignoresSafeArea()
            }
        }
        .task(id: item.id) {
            image = await loadFull(item.url)
        }
    }
}
