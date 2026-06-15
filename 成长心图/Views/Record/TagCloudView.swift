import SwiftUI

/// Tag 云图浮窗 — 气泡形式浏览所有 tag
struct TagCloudView: View {
    let allTags: [String]          // 所有 tag（含层级）
    let tagCounts: [String: Int]   // 每个 tag 的出现次数
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var searchText = ""

    /// 解析为叶子 tag + 频率
    private var leafEntries: [(tag: String, count: Int, fullPath: String)] {
        var map: [String: (count: Int, paths: Set<String>)] = [:]
        for (fullPath, count) in tagCounts {
            let leaf = leafName(fullPath)
            var entry = map[leaf] ?? (0, [])
            entry.count += count
            entry.paths.insert(fullPath)
            map[leaf] = entry
        }
        return map.map { ($0.key, $0.value.count, $0.value.paths.first ?? $0.key) }
            .filter { searchText.isEmpty || $0.tag.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.count > $1.count }
    }

    private let tagColors: [Color] = [
        ZenColor.gold, ZenColor.vermilionLight, ZenColor.jade,
        Color.themeInfo, Color.themePrimary, Color.themeSecondary,
        ZenColor.goldDeep, Color(hex: "8A7BA0"), ZenColor.vermilion,
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.themeTextTertiary)
                    TextField("搜索标签...", text: $searchText).textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.themeTextTertiary)
                        }
                    }
                }
                .padding(10).background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface).cornerRadius(10)
                .padding()

                // Tag 云
                if leafEntries.isEmpty {
                    Spacer()
                    Text("暂无标签").foregroundColor(.themeTextTertiary)
                    Spacer()
                } else {
                    ScrollView {
                        TagBubbleLayout(entries: leafEntries, colors: tagColors, onTap: onSelect)
                            .padding()
                    }
                }
            }
            .background(ZenColorScheme.background(for: cs))
            .navigationTitle("标签云")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func leafName(_ tag: String) -> String {
        tag.components(separatedBy: "/").last ?? tag
    }
}

// MARK: - 气泡布局
struct TagBubbleLayout: View {
    let entries: [(tag: String, count: Int, fullPath: String)]
    let colors: [Color]
    let onTap: (String) -> Void

    var body: some View {
        let maxCount = entries.map(\.count).max() ?? 1

        FlowLayout(spacing: 10) {
            ForEach(entries, id: \.tag) { entry in
                let ratio = CGFloat(entry.count) / CGFloat(maxCount)
                let size: CGFloat = 10 + ratio * 18  // 10-28
                let color = colors[abs(entry.tag.hashValue) % colors.count]

                Button {
                    onTap(entry.fullPath)
                } label: {
                    Text("#\(entry.tag)")
                        .font(.system(size: size, weight: ratio > 0.5 ? .medium : .regular))
                        .foregroundColor(color)
                        .padding(.horizontal, size * 0.5)
                        .padding(.vertical, size * 0.25)
                        .background(
                            RoundedRectangle(cornerRadius: size * 0.5)
                                .fill(color.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.5)
                                .stroke(color.opacity(0.25), lineWidth: 0.5)
                        )
                }
            }
        }
    }
}

// MARK: - 侧边面板版
struct TagCloudPanel: View {
    let allTags: [String]
    let tagCounts: [String: Int]
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var cs
    @State private var searchText = ""

    private var leafEntries: [(tag: String, count: Int, fullPath: String)] {
        var map: [String: (count: Int, paths: Set<String>)] = [:]
        for (fullPath, count) in tagCounts {
            let leaf = fullPath.components(separatedBy: "/").last ?? fullPath
            var entry = map[leaf] ?? (0, [])
            entry.count += count
            entry.paths.insert(fullPath)
            map[leaf] = entry
        }
        return map.map { ($0.key, $0.value.count, $0.value.paths.first ?? $0.key) }
            .filter { searchText.isEmpty || $0.tag.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.count > $1.count }
    }

    private let tagColors: [Color] = [
        ZenColor.gold, ZenColor.vermilionLight, ZenColor.jade,
        Color.themeInfo, Color.themePrimary, Color.themeSecondary,
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text("标签云").font(.headline).foregroundColor(.themeTextPrimary)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundColor(.themeTextTertiary)
                }
            }.padding()

            // 搜索
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.themeTextTertiary)
                TextField("搜索...", text: $searchText).textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.themeTextTertiary)
                    }
                }
            }.padding(10).background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface).cornerRadius(10).padding(.horizontal)

            // 云
            if leafEntries.isEmpty {
                Spacer()
                Text("暂无标签").foregroundColor(.themeTextTertiary)
                Spacer()
            } else {
                ScrollView {
                    TagBubbleLayout(entries: leafEntries, colors: tagColors, onTap: onSelect).padding()
                }
            }
        }
        .background(ZenColorScheme.background(for: cs).ignoresSafeArea())
        .overlay(
            Rectangle().fill(Color.clear).frame(width: 1).background(cs == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)),
            alignment: .leading
        )
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let h = rows.map { row in row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0, +)
        return CGSize(width: proposal.width ?? .infinity, height: h + spacing * CGFloat(max(rows.count - 1, 0)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for view in row {
                let s = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += s.width + spacing
            }
            y += (row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0) + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = []
        var cur: [LayoutSubviews.Element] = []
        var w: CGFloat = 0
        let maxW = proposal.width ?? .infinity
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if !cur.isEmpty, w + s.width + spacing > maxW {
                rows.append(cur); cur = [v]; w = s.width
            } else {
                cur.append(v); w += s.width + (cur.count > 1 ? spacing : 0)
            }
        }
        if !cur.isEmpty { rows.append(cur) }
        return rows
    }
}
