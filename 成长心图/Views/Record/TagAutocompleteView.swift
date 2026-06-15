import SwiftUI

/// Tag 自动补全浮层 — Flomo 风格
struct TagAutocompleteView: View {
    let allTags: [String]            // 所有已有tag（含层级）
    let recentTags: [String]         // 最近6个tag
    let filterText: String           // 当前输入的tag文字（#后的部分）
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var filteredSuggestions: [String] {
        if filterText.isEmpty {
            return Array(recentTags.prefix(6))
        }
        // 模糊匹配 — 按匹配度排序
        let lower = filterText.lowercased()
        return allTags
            .filter { $0.lowercased().contains(lower) }
            .sorted { a, b in
                // 前缀匹配优先
                let aPref = a.lowercased().hasPrefix(lower)
                let bPref = b.lowercased().hasPrefix(lower)
                if aPref != bPref { return aPref }
                return a.count < b.count
            }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    if filterText.isEmpty {
                        Text("最近使用")
                            .font(.system(size: 10))
                            .foregroundColor(.themeTextTertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }

                    ForEach(filteredSuggestions, id: \.self) { tag in
                        Button {
                            onSelect(tag)
                        } label: {
                            HStack {
                                Text("#\(tag)")
                                    .font(.system(size: 13))
                                    .foregroundColor(ZenColor.gold)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if tag != filteredSuggestions.last {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .background(colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                .padding(.horizontal, 4)
            }
        }
    }
}

/// 层级 Tag 解析工具
struct TagParser {
    /// 解析 "领域/科技/AI" → ["领域", "领域/科技", "领域/科技/AI"]
    static func expandHierarchy(_ tag: String) -> [String] {
        let parts = tag.split(separator: "/").map(String.init)
        var result: [String] = []
        for i in 0..<parts.count {
            result.append(parts[0...i].joined(separator: "/"))
        }
        return result
    }

    /// 获取所有层级 tag（用于索引）
    static func allHierarchyTags(from tags: [String]) -> [String] {
        var all = Set<String>()
        for tag in tags {
            for h in expandHierarchy(tag) {
                all.insert(h)
            }
        }
        return Array(all).sorted()
    }
}
