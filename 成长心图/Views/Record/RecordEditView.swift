import SwiftUI

/// 统一编辑器 — Flomo 风格 #Tag 浮选
struct RecordEditView: View {
    @ObservedObject var viewModel: RecordViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var text: String = ""
    @State private var date: Date = Date()
    @State private var category: String = "其他"
    @State private var isExperience: Bool = true

    @State private var showAutocomplete = false
    @State private var partialTag: String = ""

    /// 从文本末尾检测未闭合的 #tag
    private func detectPartialTag() -> String {
        guard let lastHash = text.lastIndex(of: "#") else { return "" }
        let after = String(text[text.index(after: lastHash)...])
        // 如果 # 后面有空格或换行 → 已闭合，不算
        if after.contains(" ") || after.contains("\n") || after.isEmpty { return "" }
        // # 后面是纯 tag 文字
        return after
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 10) {
                    // 类型 + 日期行
                    HStack(spacing: 10) {
                        Picker("", selection: $isExperience) {
                            Text("经历").tag(true)
                            Text("日记").tag(false)
                        }
                        .pickerStyle(.segmented).frame(width: 110)

                        DatePicker("", selection: $date, displayedComponents: isExperience ? .date : [.date, .hourAndMinute])
                            .labelsHidden().environment(\.locale, Locale(identifier: "zh_CN"))

                        Spacer()

                        if isExperience {
                            Menu {
                                ForEach(ExperienceCategory.allCases) { cat in
                                    Button(cat.rawValue) { category = cat.rawValue }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: ExperienceCategory.allCases.first(where: { $0.rawValue == category })?.iconName ?? "circle").font(.caption)
                                    Text(category).font(.caption)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(ZenColor.gold.opacity(0.1)).cornerRadius(8)
                            }
                        }
                    }

                    // 编辑器
                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text(isExperience ? "记录经历... 输入 #标签 标记关键词" : "写日记... 输入 #标签 标记心情")
                                    .foregroundColor(.themeTextTertiary)
                                    .padding(.horizontal, 14).padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $text)
                                .font(.body)
                                .padding(10)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .onChange(of: text) { _ in updateAutocomplete() }
                        }
                        .frame(maxHeight: .infinity)
                        .background(colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface)
                        .cornerRadius(12)

                        // Tag 预览行
                        let tags = viewModel.extractHashtags(from: text)
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(tags, id: \.self) { tag in
                                        Text("#\(tag)").font(.caption).foregroundColor(ZenColor.gold)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(ZenColor.gold.opacity(0.1)).cornerRadius(6)
                                    }
                                }.padding(.horizontal, 4).padding(.top, 6)
                            }
                        }
                    }
                }
                .padding()

                // Flomo 风格 Tag 浮窗 — 键盘上方
                if showAutocomplete {
                    TagSuggestionPanel(
                        partial: partialTag,
                        allTags: viewModel.allTags,
                        recentTags: recentTags(),
                        onSelect: { tag in insertTag(tag) },
                        onDismiss: { dismissAutocomplete() }
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(viewModel.editingExperience != nil || viewModel.editingDiary != nil ? "编辑" : (isExperience ? "记录经历" : "写日记"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }.fontWeight(.semibold)
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }

    // MARK: - Tag 逻辑
    private func updateAutocomplete() {
        let partial = detectPartialTag()
        partialTag = partial

        // 检测到未闭合 # → 显示浮窗
        if text.contains("#") && !partial.isEmpty || (text.hasSuffix("#") && partial.isEmpty) {
            if text.hasSuffix("#") { partialTag = "" }
            withAnimation(.easeOut(duration: 0.12)) { showAutocomplete = true }
        } else if partial.isEmpty && !text.hasSuffix("#") {
            dismissAutocomplete()
        }
    }

    private func dismissAutocomplete() {
        withAnimation(.easeOut(duration: 0.12)) { showAutocomplete = false }
    }

    /// 插入 tag：替换最后一个 #partial → #fulltag
    private func insertTag(_ tag: String) {
        guard let lastHash = text.lastIndex(of: "#") else { return }
        let before = String(text[..<lastHash])
        text = before + "#" + tag + " "
        dismissAutocomplete()
    }

    /// 最近使用的 6 个 tag
    private func recentTags() -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for r in viewModel.records.prefix(30) {
            for t in r.tags where !t.isEmpty && !seen.contains(t) { seen.insert(t); result.append(t) }
            for t in viewModel.extractHashtags(from: r.content) where !t.isEmpty && !seen.contains(t) { seen.insert(t); result.append(t) }
        }
        return Array(result.prefix(6))
    }

    // MARK: - 数据
    private func loadData() {
        if viewModel.editType == .experience {
            isExperience = true
            if let exp = viewModel.editingExperience { text = exp.detailText; date = exp.date; category = exp.category }
        } else {
            isExperience = false
            if let d = viewModel.editingDiary { text = d.content; date = d.date }
        }
    }

    private func save() {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let title = String(t.prefix(20))
        let tags = viewModel.extractHashtags(from: t)
        if isExperience { viewModel.saveExperience(title: title, detailText: t, date: date, category: category, tags: tags) }
        else { viewModel.saveDiary(title: title, content: t, date: date, tags: tags) }
        dismiss()
    }
}

// MARK: - Flomo 风格浮窗
struct TagSuggestionPanel: View {
    let partial: String
    let allTags: [String]
    let recentTags: [String]
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var cs

    /// 匹配 + 子集展开
    var suggestionItems: [(tag: String, isChild: Bool)] {
        if partial.isEmpty { return recentTags.map { ($0, false) } }

        let lower = partial.lowercased()
        var seen = Set<String>()
        var result: [(String, Bool)] = []

        // 1. 先找直接匹配的 tag
        let direct = allTags
            .filter { $0.lowercased().contains(lower) }
            .sorted { a, b in
                let ap = a.lowercased().hasPrefix(lower)
                let bp = b.lowercased().hasPrefix(lower)
                if ap != bp { return ap }
                return a.count < b.count
            }

        // 2. 收集子集标签（以匹配 tag 为前缀的更深层级 tag）
        var children: [(String, String)] = []  // (childTag, parentTag)
        for tag in direct {
            let prefix = tag + "/"
            let subs = allTags.filter { $0.hasPrefix(prefix) && $0 != tag }
            for sub in subs {
                children.append((sub, tag))
            }
        }

        // 3. 合并：父tag → 子tag 缩进排列
        for tag in direct.prefix(6) {
            if !seen.contains(tag) {
                seen.insert(tag)
                result.append((tag, false))
            }
            // 插入子集
            for (child, _) in children where child.hasPrefix(tag + "/") && !seen.contains(child) {
                seen.insert(child)
                result.append((child, true))
            }
        }

        return Array(result.prefix(12))
    }

    var body: some View {
        VStack(spacing: 0) {
            if !suggestionItems.isEmpty {
                HStack {
                    Text(partial.isEmpty ? "最近使用" : "匹配标签\(suggestionItems.count > 6 ? " (+子集)" : "")").font(.system(size: 10)).foregroundColor(.themeTextTertiary)
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.caption).foregroundColor(.themeTextTertiary)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)

                ForEach(Array(suggestionItems.enumerated()), id: \.element.tag) { idx, item in
                    Button {
                        onSelect(item.tag)
                    } label: {
                        HStack {
                            if item.isChild {
                                Text("└ #\(leafName(item.tag))")
                                    .font(.system(size: 13))
                                    .foregroundColor(ZenColor.gold.opacity(0.7))
                                    .padding(.leading, 20)
                            } else {
                                Text("#\(item.tag)")
                                    .font(.system(size: 14))
                                    .foregroundColor(ZenColor.gold)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if idx < suggestionItems.count - 1 { Divider().padding(.leading, 14) }
                }
            }
        }
        .background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
    }

    private func leafName(_ tag: String) -> String {
        tag.components(separatedBy: "/").last ?? tag
    }
}
