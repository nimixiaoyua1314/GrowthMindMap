import SwiftUI

/// 统一记录视图
struct RecordView: View {
    @ObservedObject var viewModel: RecordViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showTagPanel = false
    @State private var showTagCloud = false
    @State private var showTagDirectory = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                topTitleBar.padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 6)
                searchBar.padding(.horizontal, 16).padding(.bottom, 4)
                if showTagPanel { tagFilterPanel.transition(.move(edge: .top).combined(with: .opacity)) }
                statsBar.padding(.horizontal, 16).padding(.vertical, 4)
                if viewModel.filteredRecords.isEmpty { emptyState }
                else { recordList }
            }
            .padding(.bottom, 60)

            addButton.padding(.bottom, 4)

            // 标签目录 — 右侧悬浮面板（对调后）
            if showTagDirectory {
                Color.black.opacity(0.2).ignoresSafeArea()
                    .onTapGesture { withAnimation { showTagDirectory = false } }
                    .transition(.opacity)

                HStack {
                    Spacer()
                    TagDirectoryPanel(
                        allTags: viewModel.allTags,
                        tagCounts: buildTagCounts(),
                        onSelect: { tag in
                            viewModel.selectedTag = tag
                            withAnimation { showTagDirectory = false }
                        },
                        onDismiss: { withAnimation { showTagDirectory = false } }
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.72)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showTagDirectory)
        .sheet(isPresented: $viewModel.isShowingEditor) { RecordEditView(viewModel: viewModel) }
        .sheet(isPresented: $showTagCloud) {
            TagCloudView(
                allTags: viewModel.allTags,
                tagCounts: buildTagCounts(),
                onSelect: { tag in viewModel.selectedTag = tag; showTagCloud = false }
            )
        }
    }

    private func buildTagCounts() -> [String: Int] {
        var c: [String: Int] = [:]
        for r in viewModel.records {
            for t in r.tags where !t.isEmpty { c[t, default:0] += 1 }
            for t in viewModel.extractHashtags(from: r.content) where !t.isEmpty { c[t, default:0] += 1 }
        }
        return c
    }

    // MARK: - 标题行
    private var topTitleBar: some View {
        HStack {
            Text("记录").font(.system(size:28,weight:.medium,design:.serif)).foregroundColor(ZenColorScheme.text(for:colorScheme))
            Spacer()
            Button { withAnimation(.spring()) { showTagPanel.toggle() } } label: {
                HStack(spacing:4) {
                    Image(systemName: showTagPanel ? "tag.fill":"tag").font(.system(size:13))
                    Text("标签").font(.system(size:13))
                }
                .foregroundColor(showTagPanel ? ZenColor.gold:.themeTextSecondary)
                .padding(.horizontal,12).padding(.vertical,6)
                .background(showTagPanel ? ZenColor.gold.opacity(0.1):Color.clear).cornerRadius(8)
            }
            Button { withAnimation { showTagDirectory = true } } label: {
                Image(systemName:"folder.fill").font(.system(size:13)).foregroundColor(.themeTextSecondary).padding(.horizontal,6).padding(.vertical,6)
            }
            Button { showTagCloud = true } label: {
                Image(systemName:"circle.grid.3x3.fill").font(.system(size:13)).foregroundColor(.themeTextSecondary).padding(.horizontal,6).padding(.vertical,6)
            }
        }
    }

    // MARK: - 搜索条
    private var searchBar: some View {
        HStack(spacing:8) {
            HStack {
                Image(systemName:"magnifyingglass").foregroundColor(.themeTextTertiary).font(.caption)
                TextField("搜索...",text:$viewModel.searchText).textFieldStyle(.plain).font(.subheadline)
                if !viewModel.searchText.isEmpty { Button{viewModel.searchText=""} label:{Image(systemName:"xmark.circle.fill").foregroundColor(.themeTextTertiary).font(.caption)} }
            }.padding(8).background(colorScheme == .dark ? ZenColor.darkSurface:Color.themeSurface).cornerRadius(10)
            Menu {
                Button("全部"){viewModel.selectedType=nil}
                Button("经历"){viewModel.selectedType="经历"}
                Button("日记"){viewModel.selectedType="日记"}
            } label: {
                Image(systemName:viewModel.selectedType==nil ? "line.3.horizontal.decrease.circle":"line.3.horizontal.decrease.circle.fill")
                    .font(.system(size:18)).foregroundColor(viewModel.selectedType != nil ? ZenColor.gold:.themeTextSecondary)
            }
        }
    }

    private var tagFilterPanel: some View {
        let allH = TagParser.allHierarchyTags(from: viewModel.allTags)
        return ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:6) {
                FilterChip(label:"全部",isSelected:viewModel.selectedTag==nil){withAnimation{viewModel.selectedTag=nil}}
                ForEach(allH,id:\.self){tag in FilterChip(label:tag,isSelected:viewModel.selectedTag==tag){withAnimation{viewModel.selectedTag = (viewModel.selectedTag==tag ? nil:tag)}}}
            }.padding(.horizontal,16).padding(.vertical,8)
        }.background(colorScheme == .dark ? ZenColor.darkSurface.opacity(0.5):ZenColor.ricePaper.opacity(0.5))
    }

    private var statsBar: some View {
        HStack(spacing:0) {
            Text("共 \(viewModel.stats.total) 条").font(.caption2).foregroundColor(.themeTextTertiary)
            if viewModel.selectedTag != nil || viewModel.selectedType != nil || !viewModel.searchText.isEmpty {
                Text(" · 筛选出 \(viewModel.filteredRecords.count) 条").font(.caption2).foregroundColor(ZenColor.gold)
            }
            Spacer()
        }
    }

    private var addButton: some View {
        Menu {
            Button{viewModel.addExperience()}label:{Label("新增经历",systemImage:"book.fill")}
            Button{viewModel.addDiary()}label:{Label("新增日记",systemImage:"square.and.pencil.fill")}
        } label: {
            ZStack {
                Circle().fill(ZenColor.gold).frame(width:48,height:48).shadow(color:ZenColor.gold.opacity(0.3),radius:8,y:2)
                Image(systemName:"plus").font(.system(size:22,weight:.medium)).foregroundColor(.white)
            }
        }
    }

    private var recordList: some View {
        List {
            ForEach(viewModel.filteredRecords){entry in
                RecordCardView(entry:entry)
                    .listRowSeparator(.hidden).listRowInsets(EdgeInsets(top:3,leading:14,bottom:3,trailing:14)).listRowBackground(Color.clear)
                    .onTapGesture{viewModel.editEntry(entry)}
                    .swipeActions(edge:.trailing,allowsFullSwipe:false){Button(role:.destructive){viewModel.deleteEntry(entry)}label:{Label("删除",systemImage:"trash")}}
            }
        }.listStyle(.plain).scrollContentBackground(.hidden).refreshable{viewModel.fetchAll()}
    }

    private var emptyState: some View {
        VStack(spacing:12) {
            Spacer().frame(height:60)
            Image(systemName:"doc.text.magnifyingglass").font(.system(size:36)).foregroundColor(.themeTextTertiary)
            Text(viewModel.records.isEmpty ? "还没有记录":"无匹配结果").font(.subheadline).foregroundColor(.themeTextSecondary)
            if viewModel.records.isEmpty {
                Text("用 #标签 标记关键词\n支持 #领域/子类 层级标签").font(.caption).foregroundColor(.themeTextTertiary).multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
}

// MARK: - RecordCardView
struct RecordCardView: View {
    let entry: RecordEntry
    @Environment(\.colorScheme) private var cs

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: entry.typeIcon).font(.caption2).foregroundColor(entry.typeColor)
                .frame(width: 20, height: 20).background(entry.typeColor.opacity(0.1)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.typeLabel).font(.caption2).fontWeight(.medium).foregroundColor(entry.typeColor)
                        .padding(.horizontal, 6).padding(.vertical, 1).background(entry.typeColor.opacity(0.1)).cornerRadius(4)
                    if !entry.category.isEmpty && entry.category != "日记" { Text(entry.category).font(.caption2).foregroundColor(.themeTextTertiary) }
                    Spacer()
                    Text(entry.date.relativeDescription).font(.caption2).foregroundColor(.themeTextTertiary)
                }
                Text(entry.content).font(.subheadline).foregroundColor(.themeTextSecondary).lineLimit(3)
                let allT = entry.tags + extractTags(entry.content)
                let leaf = Array(Set(allT.map { $0.components(separatedBy: "/").last ?? $0 }))
                if !leaf.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(leaf.prefix(5), id: \.self) { t in
                                Text("#\(t)").font(.caption2).foregroundColor(.themePrimary)
                                    .padding(.horizontal, 6).padding(.vertical, 1).background(Color.themePrimary.opacity(0.06)).cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(12).background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface).cornerRadius(12)
    }

    private func extractTags(_ text: String) -> [String] {
        guard let r = try? NSRegularExpression(pattern: "#([\\w\\u4e00-\\u9fff/]+)") else { return [] }
        return r.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { Range($0.range(at: 1), in: text).map { String(text[$0]) } }
    }
}
