import SwiftUI
import UIKit

/// 可缩放图片视图（UIScrollView）：
/// - 双指缩放；放大后可拖动；双击在 1× 与 2.5× 间切换；
/// - 未缩放时：左右滑 → onSwipe(±1) 切换；下滑 → onSwipeDown 退出；
/// - 单击 → onSingleTap（显示/隐藏界面）；长按 → onLongPress（收藏）。
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    var onSwipe: (Int) -> Void
    var onSingleTap: () -> Void
    var onLongPress: () -> Void
    var onSwipeDown: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIScrollView {
        let sv = UIScrollView()
        sv.backgroundColor = .black
        sv.minimumZoomScale = 1
        sv.maximumZoomScale = 4
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.isScrollEnabled = false          // 1× 时不平移；放大后由 didZoom 打开
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

        let lp = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.onLongPress(_:)))
        lp.minimumPressDuration = 0.4
        sv.addGestureRecognizer(lp)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.onPan(_:)))
        pan.delegate = context.coordinator
        sv.addGestureRecognizer(pan)
        context.coordinator.pan = pan

        return sv
    }

    func updateUIView(_ sv: UIScrollView, context: Context) {
        context.coordinator.parent = self
        guard let iv = context.coordinator.imageView,
              context.coordinator.lastImage !== image else { return }
        context.coordinator.lastImage = image
        sv.setZoomScale(1, animated: false)
        sv.isScrollEnabled = false
        iv.frame = sv.bounds
        UIView.transition(with: iv, duration: 0.22,
                          options: [.transitionCrossDissolve, .allowUserInteraction]) {
            iv.image = image
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: ZoomableImageView
        weak var imageView: UIImageView?
        weak var pan: UIPanGestureRecognizer?
        var lastImage: UIImage?

        init(_ parent: ZoomableImageView) { self.parent = parent }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.isScrollEnabled = scrollView.zoomScale > 1.01
        }

        @objc func onSingleTap() { parent.onSingleTap() }

        @objc func onLongPress(_ g: UILongPressGestureRecognizer) {
            guard g.state == .began else { return }
            parent.onLongPress()
        }

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
            if abs(t.x) > abs(t.y) {
                if t.x < -60 { parent.onSwipe(1) }
                else if t.x > 60 { parent.onSwipe(-1) }
            } else if t.y > 80 {
                parent.onSwipeDown()
            }
        }

        // 只在"未缩放 + 横向 或 向下"时接管；放大后交回 scrollView 平移
        func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
            guard gr === pan else { return true }
            guard let p = gr as? UIPanGestureRecognizer, let sv = p.view as? UIScrollView else { return false }
            if sv.zoomScale > 1.01 { return false }
            let v = p.velocity(in: sv)
            if abs(v.x) > abs(v.y) * 1.2 { return true }
            if v.y > 0 && abs(v.y) > abs(v.x) * 1.2 { return true }
            return false
        }
    }
}
