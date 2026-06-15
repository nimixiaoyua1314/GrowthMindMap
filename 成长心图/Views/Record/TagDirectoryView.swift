import SwiftUI

/// 层级 Tag 目录：a/b/c → 可逐级深入选择
struct TagDirectoryView: View {
    let allTags: [String]
    let tagCounts: [String: Int]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs

    @State private var currentPath: [String] = []  // 当前导航路径

    /// 当前层级下的直接子 tag
    private var currentItems: [TagDirItem] {
        let prefix = currentPath.isEmpty ? "" : currentPath.joined(separator: "/") + "/"
        var map: [String: (count: Int, hasChildren: Bool)] = [:]

        for (full, count) in tagCounts {
            guard full.hasPrefix(prefix), full != prefix.dropLast() else { continue }
            let remainder = String(full.dropFirst(prefix.count))
            let parts = remainder.split(separator: "/", maxSplits: 1)
            let name = String(parts[0])
            var entry = map[name] ?? (0, false)
            entry.count += count
            if parts.count > 1 { entry.hasChildren = true }
            map[name] = entry
        }

        return map.map { TagDirItem(name: $0.key, count: $0.value.count, hasChildren: $0.value.hasChildren) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 面包屑
                breadcrumbBar

                // 列表
                if currentItems.isEmpty {
                    Spacer()
                    Text(currentPath.isEmpty ? "暂无标签" : "此分类下无子标签")
                        .font(.subheadline).foregroundColor(.themeTextTertiary)
                    Spacer()
                } else {
                    List {
                        ForEach(currentItems) { item in
                            Button {
                                if item.hasChildren {
                                    currentPath.append(item.name)
                                } else {
                                    let full = (currentPath + [item.name]).joined(separator: "/")
                                    onSelect(full)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: item.hasChildren ? "folder.fill" : "tag.fill")
                                        .font(.caption).foregroundColor(item.hasChildren ? ZenColor.gold : ZenColor.jade)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("#\(item.name)")
                                            .font(.subheadline).foregroundColor(.themeTextPrimary)
                                        if !currentPath.isEmpty {
                                            Text((currentPath + [item.name]).joined(separator: "/"))
                                                .font(.system(size: 10)).foregroundColor(.themeTextTertiary)
                                        }
                                    }

                                    Spacer()

                                    Text("\(item.count)")
                                        .font(.caption).foregroundColor(.themeTextTertiary)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(cs == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                                        .cornerRadius(8)

                                    if item.hasChildren {
                                        Image(systemName: "chevron.right")
                                            .font(.caption2).foregroundColor(.themeTextTertiary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(ZenColorScheme.background(for: cs))
            .navigationTitle("标签目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !currentPath.isEmpty {
                        Button {
                            onSelect(currentPath.joined(separator: "/"))
                            dismiss()
                        } label: {
                            Text("选此层级").font(.caption)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 面包屑
    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    withAnimation { currentPath = [] }
                } label: {
                    Text("全部").font(.caption)
                        .foregroundColor(currentPath.isEmpty ? ZenColor.gold : .themeTextSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(currentPath.isEmpty ? ZenColor.gold.opacity(0.12) : Color.clear)
                        .cornerRadius(6)
                }

                ForEach(currentPath.indices, id: \.self) { i in
                    Image(systemName: "chevron.right").font(.caption2).foregroundColor(.themeTextTertiary)

                    Button {
                        withAnimation { currentPath = Array(currentPath.prefix(i + 1)) }
                    } label: {
                        Text(currentPath[i]).font(.caption)
                            .foregroundColor(i == currentPath.count - 1 ? ZenColor.gold : .themeTextSecondary)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(i == currentPath.count - 1 ? ZenColor.gold.opacity(0.12) : Color.clear)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .background(cs == .dark ? ZenColor.darkSurface.opacity(0.5) : Color.themeSurface.opacity(0.5))
    }
}

// MARK: - 侧边面板版（无限层级 / 嵌套）
struct TagDirectoryPanel: View {
    let allTags: [String]
    let tagCounts: [String: Int]
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var cs
    @State private var navStack: [String] = []

    private var currentItems: [TagDirItem] {
        let prefix = navStack.isEmpty ? "" : navStack.joined(separator: "/") + "/"
        var map: [String: (count: Int, hasChildren: Bool)] = [:]
        for (full, count) in tagCounts {
            guard full.hasPrefix(prefix), full != String(prefix.dropLast()) else { continue }
            let rem = String(full.dropFirst(prefix.count))
            let parts = rem.split(separator: "/", maxSplits: 1)
            let name = String(parts[0])
            var entry = map[name] ?? (0, false)
            entry.count += count
            if parts.count > 1 { entry.hasChildren = true }
            map[name] = entry
        }
        return map.map { TagDirItem(name: $0.key, count: $0.value.count, hasChildren: $0.value.hasChildren) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text("标签目录").font(.headline).foregroundColor(.themeTextPrimary)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundColor(.themeTextTertiary)
                }
            }.padding()

            // 面包屑
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    Button { withAnimation { navStack = [] } } label: {
                        Text(navStack.isEmpty ? "• 全部" : "← 返回").font(.caption)
                            .foregroundColor(ZenColor.gold).padding(.horizontal, 8).padding(.vertical, 4)
                    }
                    ForEach(navStack.indices, id: \.self) { i in
                        Image(systemName: "chevron.right").font(.caption2).foregroundColor(.themeTextTertiary)
                        Button { withAnimation { navStack = Array(navStack.prefix(i+1)) } } label: {
                            Text(navStack[i]).font(.caption)
                                .foregroundColor(i == navStack.count-1 ? .themeTextPrimary : ZenColor.gold)
                                .padding(.horizontal, 6).padding(.vertical, 4)
                                .background(i == navStack.count-1 ? ZenColor.gold.opacity(0.08) : Color.clear).cornerRadius(4)
                        }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 8)
            }

            // 选中当前层级
            if !navStack.isEmpty {
                Button {
                    onSelect(navStack.joined(separator: "/"))
                    onDismiss()
                } label: {
                    Label("选中「\(navStack.joined(separator: "/"))」及其所有子集", systemImage: "checkmark.circle")
                        .font(.caption).foregroundColor(ZenColor.jade)
                }.padding(.horizontal, 16).padding(.bottom, 8)
            }

            // 列表
            if currentItems.isEmpty {
                Spacer()
                Text("此层级无子标签").font(.subheadline).foregroundColor(.themeTextTertiary)
                Spacer()
            } else {
                List {
                    ForEach(currentItems) { item in
                        let fullPath = navStack.isEmpty ? item.name : navStack.joined(separator: "/") + "/" + item.name
                        Button {
                            if item.hasChildren {
                                withAnimation { navStack.append(item.name) }
                            } else {
                                onSelect(fullPath)
                                onDismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: item.hasChildren ? "folder.fill" : "tag.fill")
                                    .font(.caption).foregroundColor(item.hasChildren ? ZenColor.gold : ZenColor.jade).frame(width: 22)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("#\(item.name)").font(.subheadline).foregroundColor(.themeTextPrimary)
                                    if !navStack.isEmpty { Text(fullPath).font(.system(size:9)).foregroundColor(.themeTextTertiary) }
                                }
                                Spacer()
                                Text("\(item.count)").font(.caption).foregroundColor(.themeTextTertiary)
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(cs == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)).cornerRadius(8)
                                if item.hasChildren { Image(systemName: "chevron.right").font(.caption2).foregroundColor(.themeTextTertiary) }
                            }.padding(.vertical, 3)
                        }.buttonStyle(.plain)
                    }
                }.listStyle(.plain)
            }
        }
        .background(ZenColorScheme.background(for: cs).ignoresSafeArea())
        .overlay(Rectangle().fill(cs == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)).frame(width: 1), alignment: .leading)
    }
}

struct TagDirItem: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let hasChildren: Bool
}
