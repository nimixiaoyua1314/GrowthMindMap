import SwiftUI

struct AnalysisView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    @ObservedObject var suggestionVM: SuggestionViewModel
    @State private var showDeepAnalysisAlert = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 如果有分析结果就展示，否则展示引导页
                    if let _ = viewModel.latestAnalysis, !viewModel.topTraits.isEmpty {
                        analysisContent
                    } else {
                        onboardingContent
                    }
                }
                .padding()
            }

            // 加载中
            if viewModel.isAnalyzing {
                analyzingOverlay
            }
        }
        .navigationTitle("特质分析")
        .alert("AI 深度分析", isPresented: $showDeepAnalysisAlert) {
            Button("取消", role: .cancel) {}
            Button("开始分析") {
                Task { await viewModel.runDeepAnalysis() }
            }
        } message: {
            Text("将使用 AI 对你的经历和日记进行深度分析。分析内容会脱敏处理，仅包含摘要信息。")
        }
    }

    // MARK: - 无数据引导
    private var onboardingContent: some View {
        VStack(spacing: 30) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.themePrimary)
            }

            VStack(spacing: 12) {
                Text("发现你的特质与使命")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextPrimary)

                Text("记录经历和日记后，\n系统将分析你的核心特质，\n帮助你发现人生方向和行动建议")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                Task { await viewModel.runLocalAnalysis() }
            } label: {
                HStack {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("开始分析")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.gradientPrimary)
                .cornerRadius(14)
            }

            if viewModel.analysisError != nil {
                Text(viewModel.analysisError ?? "")
                    .font(.caption)
                    .foregroundColor(.themeError)
                    .padding()
            }

            Spacer()
        }
    }

    // MARK: - 分析内容
    private var analysisContent: some View {
        VStack(spacing: 20) {
            // 日期和重新分析按钮
            HStack {
                if let date = viewModel.latestAnalysis?.analysisDate {
                    Text("分析于 \(date.shortChineseFormat)")
                        .font(.caption)
                        .foregroundColor(.themeTextTertiary)
                }
                Spacer()

                Button {
                    Task { await viewModel.runLocalAnalysis() }
                } label: {
                    Label("刷新分析", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.themePrimary)

                Button {
                    showDeepAnalysisAlert = true
                } label: {
                    Label("AI 深度", systemImage: "brain")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.themeSecondary)
            }

            // 雷达图
            if !viewModel.traitScores.isEmpty {
                TraitRadarChartView(traitScores: viewModel.traitScores)
                    .frame(height: 300)
                    .padding()
                    .background(Color.themeSurface)
                    .cornerRadius(16)
            }

            // 核心特质
            topTraitsCard

            // 使命卡片
            if !viewModel.inferredMission.isEmpty {
                MissionCardView(mission: viewModel.inferredMission)
            }

            // 优势 & 成长
            strengthsAndGrowthCard

            // 分析摘要
            if !viewModel.summary.isEmpty {
                summaryCard
            }

            // 生成建议按钮
            Button {
                Task {
                    await suggestionVM.generateSuggestions(from: viewModel.latestAnalysis)
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("生成行动建议")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.gradientWarm)
                .cornerRadius(14)
            }

            // 错误信息
            if let error = viewModel.analysisError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.themeError)
                    .padding()
            }
        }
    }

    // MARK: - 核心特质卡片
    private var topTraitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.themeSecondary)
                Text("核心特质")
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
            }

            ForEach(Array(viewModel.topTraits.enumerated()), id: \.element) { index, trait in
                if let def = TraitLibrary.allTraits.first(where: { $0.name == trait }),
                   let score = viewModel.traitScores[trait] {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.themePrimary)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trait)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.themeTextPrimary)

                            Text(def.description)
                                .font(.caption)
                                .foregroundColor(.themeTextSecondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text("\(Int(score))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.themePrimary)
                            + Text("%")
                            .font(.caption2)
                            .foregroundColor(.themeTextTertiary)
                    }

                    // 进度条
                    ProgressView(value: score, total: 100)
                        .tint(
                            score > 70 ? .moodGood :
                            score > 40 ? .themeInfo : .themeSecondary
                        )
                }
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(16)
    }

    // MARK: - 优势与成长
    private var strengthsAndGrowthCard: some View {
        HStack(spacing: 12) {
            // 优势
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.moodGood)
                    Text("优势领域")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                ForEach(viewModel.strengthAreas, id: \.self) { area in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.moodGood)
                        Text(area)
                            .font(.caption)
                            .foregroundColor(.themeTextPrimary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.themeSurface)
            .cornerRadius(14)

            // 成长
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "arrow.up.forward.circle.fill")
                        .foregroundColor(.themeInfo)
                    Text("成长领域")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                if viewModel.growthAreas.isEmpty {
                    Text("保持全面均衡发展")
                        .font(.caption)
                        .foregroundColor(.themeTextTertiary)
                } else {
                    ForEach(viewModel.growthAreas, id: \.self) { area in
                        HStack(spacing: 6) {
                            Image(systemName: "circle.dotted")
                                .font(.caption)
                                .foregroundColor(.themeInfo)
                            Text(area)
                                .font(.caption)
                                .foregroundColor(.themeTextPrimary)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.themeSurface)
            .cornerRadius(14)
        }
    }

    // MARK: - 摘要
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.themePrimary)
                Text("分析摘要")
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
            }

            Text(viewModel.summary)
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
                .lineSpacing(6)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(16)
    }

    // MARK: - 加载覆盖层
    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("正在分析你的特质...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("这可能需要几秒钟")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}
