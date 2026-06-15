import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAPISettings = false
    @State private var showDataManagement = false
    @State private var showAbout = false
    @StateObject private var suggestionVM: SuggestionViewModel

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _suggestionVM = StateObject(wrappedValue: SuggestionViewModel(context: ctx))
    }

    // 统计数据
    @FetchRequest(
        sortDescriptors: []
    ) private var experiences: FetchedResults<ExperienceEntity>

    @FetchRequest(
        sortDescriptors: []
    ) private var diaries: FetchedResults<DiaryEntryEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TraitAnalysisEntity.analysisDate, ascending: false)]
    ) private var analyses: FetchedResults<TraitAnalysisEntity>

    var body: some View {
        ZStack {
            ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 用户头像区域
                    userHeader

                    // 数据统计
                    dataStatsCard

                    // 活动热力图
                    DateActivityChart(dates: allActivityDates)

                    // 建议
                    suggestionsSection

                    // AI 设置
                    aiSettingsCard

                    // 设置列表
                    settingsList

                    // 底部
                    appInfo
                        .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .navigationTitle("我的")
        .sheet(isPresented: $showAPISettings) {
            APISettingsView()
        }
        .sheet(isPresented: $showDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    // MARK: - 用户头部
    private var userHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gradientPrimary)
                    .frame(width: 80, height: 80)

                Text(String("成长".prefix(1)))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("成长记录者")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextPrimary)

                Text("已陪伴 \(totalDays) 天")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - 数据统计卡片
    private var dataStatsCard: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "book.fill",
                iconColor: .themePrimary,
                value: "\(experiences.count)",
                label: "人生经历"
            )
            StatCard(
                icon: "square.and.pencil.fill",
                iconColor: .themeInfo,
                value: "\(diaries.count)",
                label: "日记"
            )
            StatCard(
                icon: "sparkle.magnifyingglass",
                iconColor: .themeSecondary,
                value: "\(analyses.count)",
                label: "分析次数"
            )
            StatCard(
                icon: "checkmark.circle.fill",
                iconColor: .moodGood,
                value: "\(suggestionVM.completedSuggestions.count)/\(suggestionVM.suggestions.count)",
                label: "建议进度"
            )
        }
    }

    // MARK: - 行动建议摘要
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.moodExcellent)
                Text("行动建议")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                if !suggestionVM.activeSuggestions.isEmpty {
                    Text("\(suggestionVM.activeSuggestions.count) 项待完成")
                        .font(.caption)
                        .foregroundColor(.themeTextTertiary)
                }
            }

            if suggestionVM.activeSuggestions.isEmpty {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.themeTextTertiary)
                    Text("完成特质分析后可生成建议")
                        .font(.caption)
                        .foregroundColor(.themeTextTertiary)
                    Spacer()
                }
                .padding(12)
                .background(colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface)
                .cornerRadius(10)
            } else {
                ForEach(suggestionVM.activeSuggestions.prefix(3), id: \.id) { sug in
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            withAnimation { suggestionVM.toggleCompletion(sug) }
                        } label: {
                            Image(systemName: sug.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(sug.isCompleted ? .moodGood : .themeTextTertiary)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sug.title)
                                .font(.caption).fontWeight(.medium)
                                .foregroundColor(.themeTextPrimary)
                                .lineLimit(1)
                            Text(sug.descriptionText)
                                .font(.caption2).foregroundColor(.themeTextSecondary).lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? ZenColor.darkBackground : Color.themeBackground)
        .cornerRadius(14)
    }

    // MARK: - AI 设置卡片
    private var aiSettingsCard: some View {
        Button {
            showAPISettings = true
        } label: {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.themeSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 深度分析配置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.themeTextPrimary)

                    Text(aiStatusText)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.themeTextTertiary)
            }
            .padding()
            .background(Color.themeSurface)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 设置列表
    @AppStorage("colorScheme") private var storedColorScheme: String = "system"

    private var settingsList: some View {
        VStack(spacing: 0) {
            // 日/夜模式
            HStack {
                Image(systemName: "moonphase.first.quarter").font(.body).foregroundColor(ZenColor.gold).frame(width: 28)
                Text("外观模式").font(.body).foregroundColor(.themeTextPrimary)
                Spacer()
                Picker("", selection: $storedColorScheme) {
                    Text("跟随系统").tag("system")
                    Text("白天").tag("light")
                    Text("夜晚").tag("dark")
                }
                .pickerStyle(.segmented).frame(width: 200)
            }
            .padding(.vertical, 12).padding(.horizontal).background(Color.themeSurface)

            Divider().padding(.leading, 48)

            settingsRow(icon: "arrow.up.doc.fill", color: .themeInfo, title: "导出数据") {
                exportData()
            }

            Divider().padding(.leading, 48)

            settingsRow(icon: "trash.fill", color: .themeError, title: "数据管理") {
                showDataManagement = true
            }

            Divider().padding(.leading, 48)

            settingsRow(icon: "shield.fill", color: .moodGood, title: "隐私设置") {
                // 隐私设置
            }

            Divider().padding(.leading, 48)

            settingsRow(icon: "info.circle.fill", color: .themeTextTertiary, title: "关于成长心图") {
                showAbout = true
            }
        }
        .background(Color.themeSurface)
        .cornerRadius(14)
    }

    private func settingsRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(title)
                    .font(.body)
                    .foregroundColor(.themeTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.themeTextTertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 底部信息
    private var appInfo: some View {
        VStack(spacing: 6) {
            Text("成长心图 v1.0.0")
                .font(.caption).foregroundColor(.themeTextTertiary)
            Text("记录成长，发现使命")
                .font(.caption2).foregroundColor(.themeTextTertiary)
            Text("设计师/开发者：李爻中")
                .font(.caption2).foregroundColor(.themeTextTertiary.opacity(0.7))
            Text("453036149@qq.com")
                .font(.caption2).foregroundColor(.themeTextTertiary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 计算属性
    private var allActivityDates: [Date] {
        experiences.map { $0.date } + diaries.map { $0.date }
    }

    private var totalDays: Int {
        var allDates: [Date] = []
        allDates.append(contentsOf: experiences.map { $0.date })
        allDates.append(contentsOf: diaries.map { $0.date })

        guard let earliest = allDates.min(),
              let latest = allDates.max() else {
            return 0
        }
        return max(1, Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 1)
    }

    private var suggestionCount: Int {
        (try? context.fetch(SuggestionEntity.fetchRequest()).filter { $0.isCompleted }.count) ?? 0
    }

    private var aiStatusText: String {
        let key = UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
        return key.isEmpty ? "未配置" : "已配置 ✓"
    }

    // MARK: - 导出
    private func exportData() {
        // 生成导出文本
        var exportText = "# 成长心图 - 数据导出\n"
        exportText += "导出日期: \(Date().chineseFormat)\n\n"

        exportText += "## 人生经历 (\(experiences.count)条)\n\n"
        for exp in experiences {
            exportText += "### \(exp.title)\n"
            exportText += "- 日期: \(exp.date.chineseFormat)\n"
            exportText += "- 分类: \(exp.category)\n"
            exportText += "- 影响度: \(exp.impactLevel)/5\n"
            exportText += "- 情绪: \(exp.emotionTags.joined(separator: "、"))\n"
            exportText += "- 感悟: \(exp.lifeLessons)\n"
            exportText += "\n\(exp.detailText)\n\n"
        }

        exportText += "## 日记 (\(diaries.count)篇)\n\n"
        for diary in diaries {
            exportText += "### \(diary.title) (\(diary.date.chineseFormat))\n"
            exportText += "- 心情: \(diary.mood)/5\n"
            exportText += "\n\(diary.content)\n\n"
        }

        // 使用分享 Sheet
        let activityVC = UIActivityViewController(
            activityItems: [exportText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - 子组件

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themeTextPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(14)
    }
}

// MARK: - API 设置视图
struct APISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var apiKey: String = ""
    @State private var apiEndpoint: String = ""
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            ZStack {
                ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 20) {
                    // 说明
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI 深度分析", systemImage: "brain.head.profile")
                            .font(.headline)
                            .foregroundColor(.themeTextPrimary)

                        Text("配置 AI API 后，可以获得更深入、更个性化的特质分析和使命解读。分析数据会做脱敏处理。")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding()
                    .background(Color.themeSurface)
                    .cornerRadius(14)

                    // API Key
                    VStack(alignment: .leading, spacing: 10) {
                        Text("API Key")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.themeTextSecondary)

                        HStack {
                            if showKey {
                                TextField("输入 API Key", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("输入 API Key", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button {
                                showKey.toggle()
                            } label: {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .foregroundColor(.themeTextSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.themeSurface)
                    .cornerRadius(14)

                    // API 端点
                    VStack(alignment: .leading, spacing: 10) {
                        Text("API 端点 (可选)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.themeTextSecondary)

                        TextField("https://api.anthropic.com/v1/messages", text: $apiEndpoint)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.themeSurface)
                    .cornerRadius(14)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("AI 配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        UserDefaults.standard.set(apiKey, forKey: "llm_api_key")
                        UserDefaults.standard.set(apiEndpoint, forKey: "llm_api_endpoint")
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                apiKey = UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
                apiEndpoint = UserDefaults.standard.string(forKey: "llm_api_endpoint") ?? "https://api.anthropic.com/v1/messages"
            }
        }
    }
}

// MARK: - 数据管理视图
struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("数据管理", systemImage: "cylinder.fill")
                            .font(.headline)
                            .foregroundColor(.themeTextPrimary)

                        Text("你可以导出数据或清空所有数据。清空操作不可撤销。")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding()
                    .background(Color.themeSurface)
                    .cornerRadius(14)

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("清空所有数据")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeError)
                        .cornerRadius(14)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("数据管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("确认清空", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    PersistenceController.shared.deleteAll()
                    dismiss()
                }
            } message: {
                Text("此操作将永久删除所有经历、日记、分析和建议数据，不可恢复。")
            }
        }
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
                ZStack {
                    Circle().fill(ZenColor.gold.opacity(0.12)).frame(width: 90, height: 90)
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 36)).foregroundColor(ZenColor.gold)
                }
                VStack(spacing: 6) {
                    Text("成长心图").font(.title2).fontWeight(.medium)
                    Text("v1.0.0").font(.caption).foregroundColor(.themeTextTertiary)
                    Text("记录成长，发现使命").font(.subheadline).foregroundColor(.themeTextSecondary)
                }
                VStack(spacing: 12) {
                    AboutInfoRow(icon: "person.fill", title: "设计师/开发者", value: "李爻中")
                    AboutInfoRow(icon: "envelope.fill", title: "联系邮箱", value: "453036149@qq.com")
                    AboutInfoRow(icon: "heart.fill", title: "特别鸣谢", value: "每一个认真记录的你")
                }.padding(.horizontal, 40)
                Spacer()
            }
            .background(ZenColorScheme.background(for: cs))
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }
}

struct AboutInfoRow: View {
    let icon: String; let title: String; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 24).foregroundColor(ZenColor.gold)
            Text(title).font(.subheadline).foregroundColor(.themeTextSecondary)
            Spacer()
            Text(value).font(.subheadline).foregroundColor(.themeTextPrimary)
        }
    }
}


