import SwiftUI

/// 收藏标识（轻度特效）：进入收藏图片时，右上角心形轻微弹出后以较低透明度常驻，
/// 提示"这是收藏的图片"。查看器与幻灯片共用。
struct FavBadge: View {
    @State private var scale = 0.4
    @State private var opacity = 0.0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color(red: 0.98, green: 0.29, blue: 0.55))
            .padding(9)
            .glassOr(in: Circle(), fallback: Color.black.opacity(0.32))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    scale = 1.0
                    opacity = 0.9
                }
            }
    }
}
