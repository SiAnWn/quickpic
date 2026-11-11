import Foundation

extension Collection {
    /// 安全下标：越界返回 nil，不崩溃。
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
