import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAPISettings = false
    @State private var showDataPrivacy = false
    @State private var showAbout = false
    @StateObject private var suggestionVM: SuggestionViewModel
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("colorScheme") private var storedColorScheme: String = "system"

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _suggestionVM = StateObject(wrappedValue: SuggestionViewModel(context: ctx))
    }

    @FetchRequest(sortDescriptors: []) private var experiences: FetchedResults<ExperienceEntity>
    @FetchRequest(sortDescriptors: []) private var diaries: FetchedResults<DiaryEntryEntity>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \TraitAnalysisEntity.analysisDate, ascending: false)]) private var analyses: FetchedResults<TraitAnalysisEntity>

    var body: some View {
        ZStack {
            ZenColorScheme.background(for: colorScheme).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    userHeader
                    dataStatsCard
                    DateActivityChart(dates: allActivityDates)
                    suggestionsSection
                    aiSettingsCard
                    settingsList
                    appInfo.padding(.bottom, 40)
                }.padding()
            }
        }
        .navigationTitle("我的")
        .sheet(isPresented: $showAPISettings) { APISettingsView() }
        .sheet(isPresented: $showDataPrivacy) { DataPrivacyView() }
        .sheet(isPresented: $showAbout) { AboutView() }
    }

    // MARK: - 用户头部
    private var userHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.gradientPrimary).frame(width: 80, height: 80)
                Text(String((userName.isEmpty ? "我" : userName).prefix(1)))
                    .font(.system(size: 32, weight: .medium)).foregroundColor(.white)
            }
            VStack(spacing: 4) {
                TextField("你的名字", text: $userName)
                    .font(.title3).fontWeight(.bold).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center)
                Text("已陪伴 \(totalDays) 天").font(.caption).foregroundColor(.themeTextSecondary)
            }
        }.padding(.top, 20)
    }

    // MARK: - 统计
    private var dataStatsCard: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "book.fill", iconColor: .themePrimary, value: "\(experiences.count)", label: "人生经历")
            StatCard(icon: "square.and.pencil.fill", iconColor: .themeInfo, value: "\(diaries.count)", label: "日记")
            StatCard(icon: "sparkle.magnifyingglass", iconColor: .themeSecondary, value: "\(analyses.count)", label: "分析次数")
            StatCard(icon: "checkmark.circle.fill", iconColor: .moodGood, value: "\(suggestionVM.completedSuggestions.count)/\(suggestionVM.suggestions.count)", label: "建议进度")
        }
    }

    // MARK: - 建议
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill").foregroundColor(.moodExcellent)
                Text("行动建议").font(.subheadline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                Spacer()
                if !suggestionVM.activeSuggestions.isEmpty {
                    Text("\(suggestionVM.activeSuggestions.count) 项待完成").font(.caption).foregroundColor(.themeTextTertiary)
                }
            }
            if suggestionVM.activeSuggestions.isEmpty {
                HStack {
                    Image(systemName: "sparkles").foregroundColor(.themeTextTertiary)
                    Text("完成特质分析后可生成建议").font(.caption).foregroundColor(.themeTextTertiary)
                    Spacer()
                }.padding(12).background(surfaceColor).cornerRadius(10)
            } else {
                ForEach(suggestionVM.activeSuggestions.prefix(3), id: \.id) { sug in
                    HStack(alignment: .top, spacing: 10) {
                        Button { withAnimation { suggestionVM.toggleCompletion(sug) } } label: {
                            Image(systemName: sug.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(sug.isCompleted ? .moodGood : .themeTextTertiary)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sug.title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextPrimary).lineLimit(1)
                            Text(sug.descriptionText).font(.caption2).foregroundColor(.themeTextSecondary).lineLimit(2)
                        }
                        Spacer()
                    }.padding(10).background(surfaceColor).cornerRadius(10)
                }
            }
        }.padding().background(colorScheme == .dark ? ZenColor.darkBackground : Color.themeBackground).cornerRadius(14)
    }

    // MARK: - AI 设置
    private var aiSettingsCard: some View {
        Button { showAPISettings = true } label: {
            HStack {
                Image(systemName: "brain.head.profile").font(.title3).foregroundColor(.themeSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 深度分析配置").font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextPrimary)
                    Text(aiStatusText).font(.caption).foregroundColor(.themeTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.themeTextTertiary)
            }.padding().background(surfaceColor).cornerRadius(14)
        }.buttonStyle(.plain)
    }

    // MARK: - 设置列表
    private var settingsList: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "moonphase.first.quarter").font(.body).foregroundColor(ZenColor.gold).frame(width: 28)
                Text("外观模式").font(.body).foregroundColor(.themeTextPrimary)
                Spacer()
                Picker("", selection: $storedColorScheme) {
                    Text("跟随系统").tag("system")
                    Text("白天").tag("light")
                    Text("夜晚").tag("dark")
                }.pickerStyle(.segmented).frame(width: 200)
            }.padding(.vertical, 12).padding(.horizontal).background(surfaceColor)

            Divider().padding(.leading, 48)
            settingsRow(icon: "arrow.up.doc.fill", color: .themeInfo, title: "导出数据") { exportData() }

            Divider().padding(.leading, 48)
            settingsRow(icon: "lock.shield.fill", color: .moodGood, title: "数据与隐私") { showDataPrivacy = true }

            Divider().padding(.leading, 48)
            settingsRow(icon: "info.circle.fill", color: .themeTextTertiary, title: "关于成长心图") { showAbout = true }
        }.background(surfaceColor).cornerRadius(14)
    }

    private func settingsRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).font(.body).foregroundColor(color).frame(width: 28)
                Text(title).font(.body).foregroundColor(.themeTextPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.themeTextTertiary)
            }.padding(.horizontal).padding(.vertical, 14)
        }.buttonStyle(.plain)
    }

    private var appInfo: some View {
        VStack(spacing: 6) {
            Text("成长心图 v1.0.0").font(.caption).foregroundColor(.themeTextTertiary)
            Text("记录成长，发现使命").font(.caption2).foregroundColor(.themeTextTertiary)
            Text("设计师/开发者：李爻中").font(.caption2).foregroundColor(.themeTextTertiary.opacity(0.7))
            Text("453036149@qq.com").font(.caption2).foregroundColor(.themeTextTertiary.opacity(0.5))
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Helpers
    private var surfaceColor: Color { colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface }
    private var allActivityDates: [Date] { experiences.map { $0.date } + diaries.map { $0.date } }
    private var totalDays: Int {
        let all = (experiences.map{$0.date} + diaries.map{$0.date}).sorted()
        guard let first = all.first, let last = all.last else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: first, to: last).day ?? 1)
    }
    private var aiStatusText: String {
        (UserDefaults.standard.string(forKey: "llm_api_key") ?? "").isEmpty ? "未配置" : "已配置 ✓"
    }

    // MARK: - 导出 Markdown
    private func exportData() {
        var md = "# 成长心图 — 数据导出\n> \(Date().chineseFormat)\n\n---\n\n"
        if let a = TraitAnalysisEntity.fetchLatest(in: context) {
            md += "## 🔍 特质分析报告\n\n**核心特质**: \(a.topTraits.joined(separator: "、"))\n\n**使命**: \(a.inferredMission)\n\n**优势**: \(a.strengthAreas.joined(separator: "、"))\n\n**成长**: \(a.growthAreas.joined(separator: "、"))\n\n**摘要**: \(a.summary)\n\n---\n\n"
        }
        md += "## 📖 经历 (\(experiences.count)条)\n\n"
        for e in experiences { md += "### \(e.title)\n- 📅 \(e.date.chineseFormat) | 🏷 \(e.category)\n\n\(e.detailText)\n\n" }
        md += "---\n\n## ✍️ 日记 (\(diaries.count)篇)\n\n"
        for d in diaries { md += "### \(d.title)\n- 📅 \(d.date.shortChineseFormat)\n\n\(d.content)\n\n" }
        md += "---\n\n*成长心图 v1.0 · 李爻中*"
        let vc = UIActivityViewController(activityItems: [md], applicationActivities: nil)
        if let s = UIApplication.shared.connectedScenes.first as? UIWindowScene, let r = s.windows.first?.rootViewController { r.present(vc, animated: true) }
    }
}

// MARK: - 子组件
struct StatCard: View {
    let icon: String; let iconColor: Color; let value: String; let label: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundColor(iconColor).frame(width: 36, height: 36).background(iconColor.opacity(0.1)).clipShape(Circle())
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary)
            Text(label).font(.caption).foregroundColor(.themeTextSecondary)
        }.frame(maxWidth: .infinity).padding().background(Color.themeSurface).cornerRadius(14)
    }
}

// MARK: - API 设置
struct APISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var apiKey = UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            ZStack {
                ZenColorScheme.background(for: cs).ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI 深度分析", systemImage: "brain.head.profile").font(.headline).foregroundColor(.themeTextPrimary)
                        Text("配置后可获得更深度的特质分析。数据脱敏处理。").font(.subheadline).foregroundColor(.themeTextSecondary)
                    }.padding().background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface).cornerRadius(14)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("API Key").font(.subheadline).fontWeight(.semibold).foregroundColor(.themeTextSecondary)
                        HStack {
                            if showKey { TextField("sk-...", text: $apiKey).textFieldStyle(.roundedBorder) }
                            else { SecureField("sk-...", text: $apiKey).textFieldStyle(.roundedBorder) }
                            Button { showKey.toggle() } label: { Image(systemName: showKey ? "eye.slash" : "eye").foregroundColor(.themeTextSecondary) }
                        }
                    }.padding().background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface).cornerRadius(14)
                    Spacer()
                }.padding()
            }
            .navigationTitle("AI 配置").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("保存") { UserDefaults.standard.set(apiKey, forKey: "llm_api_key"); dismiss() }.fontWeight(.semibold) }
            }
        }
    }
}

// MARK: - 数据与隐私
struct DataPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    @State private var showDelete = false
    @AppStorage("allow_analytics") private var allowAnalytics = true
    @AppStorage("allow_ai") private var allowAI = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    privacyCard(icon: "hand.raised.fill", title: "隐私承诺", color: .moodGood) {
                        Text("所有数据存储在设备本地，不上传服务器。AI分析数据脱敏处理。我们不会收集、出售或分享你的任何个人信息。").font(.subheadline).foregroundColor(.themeTextSecondary).lineSpacing(4)
                    }
                    privacyCard(icon: "slider.horizontal.3", title: "权限管理", color: ZenColor.gold) {
                        VStack(spacing: 12) {
                            ToggleRow(icon: "chart.bar.fill", title: "使用分析数据优化体验", isOn: $allowAnalytics)
                            Divider()
                            ToggleRow(icon: "brain.head.profile", title: "允许AI深度分析", isOn: $allowAI)
                        }
                    }
                    privacyCard(icon: "lock.shield.fill", title: "数据安全", color: .themeInfo) {
                        Text("Core Data加密存储 · 应用沙盒隔离 · 删除前请导出备份").font(.subheadline).foregroundColor(.themeTextSecondary).lineSpacing(4)
                    }
                    Button { showDelete = true } label: {
                        HStack { Image(systemName: "trash.fill"); Text("清空所有数据") }
                            .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.themeError).cornerRadius(14)
                    }
                }.padding()
            }
            .background(ZenColorScheme.background(for: cs))
            .navigationTitle("数据与隐私").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("关闭") { dismiss() } } }
            .alert("确认清空", isPresented: $showDelete) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) { PersistenceController.shared.deleteAll(); dismiss() }
            } message: { Text("永久删除所有经历、日记、分析和建议数据，不可恢复。建议先导出备份。") }
        }
    }

    func privacyCard<C: View>(icon: String, title: String, color: Color, @ViewBuilder c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: icon).foregroundColor(color); Text(title).font(.headline).foregroundColor(.themeTextPrimary) }
            c()
        }.padding().background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface).cornerRadius(14)
    }
}

struct ToggleRow: View {
    let icon: String; let title: String; @Binding var isOn: Bool
    var body: some View {
        HStack { Image(systemName: icon).foregroundColor(.themeTextTertiary).frame(width:24); Text(title).font(.subheadline).foregroundColor(.themeTextPrimary); Spacer(); Toggle("", isOn: $isOn).labelsHidden() }
    }
}

// MARK: - 关于
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var cs
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)
                ZStack { Circle().fill(ZenColor.gold.opacity(0.12)).frame(width:90,height:90); Image(systemName:"circle.hexagongrid.fill").font(.system(size:36)).foregroundColor(ZenColor.gold) }
                VStack(spacing:6) { Text("成长心图").font(.title2).fontWeight(.medium); Text("v1.0.0").font(.caption).foregroundColor(.themeTextTertiary); Text("记录成长，发现使命").font(.subheadline).foregroundColor(.themeTextSecondary) }
                VStack(spacing:12) {
                    AboutRow(icon:"person.fill",title:"设计师/开发者",value:"李爻中")
                    AboutRow(icon:"envelope.fill",title:"联系邮箱",value:"453036149@qq.com")
                    AboutRow(icon:"heart.fill",title:"特别鸣谢",value:"每一个认真记录的你")
                }.padding(.horizontal,40)
                Spacer()
            }.background(ZenColorScheme.background(for: cs)).navigationTitle("关于").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement:.navigationBarTrailing){Button("完成"){dismiss()}} }
        }
    }
}
struct AboutRow: View {
    let icon: String; let title: String; let value: String
    var body: some View { HStack { Image(systemName:icon).frame(width:24).foregroundColor(ZenColor.gold); Text(title).font(.subheadline).foregroundColor(.themeTextSecondary); Spacer(); Text(value).font(.subheadline).foregroundColor(.themeTextPrimary) } }
}
