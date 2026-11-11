import Foundation

/// 文件夹名模糊匹配：忽略大小写与空白。
/// 规则：查询作为「连续子串」出现，或「按顺序（可不连续）」出现在名字里，都算匹配——
/// 因此输入任意 1–2 个字即可命中包含它们的文件夹（如「记者」「记视」「视」都能匹配「记者看到这个视频」）。
enum Fuzzy {
    private static func normalize(_ s: String) -> String {
        String(s.lowercased().unicodeScalars
            .filter { !CharSet.whitespacesAndNewlines.contains($0) })
    }

    static func match(_ query: String, _ name: String) -> Bool {
        let q = normalize(query)
        if q.isEmpty { return true }
        let n = normalize(name)
        if n.contains(q) { return true }
        // 子序列：q 的每个字符按顺序出现在 n 中即可
        var it = n.unicodeScalars.makeIterator()
        for sc in q.unicodeScalars {
            var found = false
            while let c = it.next() { if c == sc { found = true; break } }
            if !found { return false }
        }
        return true
    }

    /// 排序分数：前缀 > 连续包含 > 子序列。
    static func score(_ query: String, _ name: String) -> Int {
        let q = normalize(query), n = normalize(name)
        if q.isEmpty { return 0 }
        if n.hasPrefix(q) { return 3 }
        if n.contains(q) { return 2 }
        return 1
    }
}
