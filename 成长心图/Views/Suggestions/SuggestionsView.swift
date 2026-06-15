import SwiftUI

struct SuggestionsView: View {
    @ObservedObject var viewModel: SuggestionViewModel
    @State private var showCompleted = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // 进度概览
                progressHeader

                // 切换已完成/未完成
                Picker("显示", selection: $showCompleted) {
                    Text("进行中").tag(false)
                    Text("已完成").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // 列表
                if showCompleted {
                    if viewModel.completedSuggestions.isEmpty {
                        emptyCompletedState
                    } else {
                        suggestionList(viewModel.completedSuggestions)
                    }
                } else {
                    if viewModel.activeSuggestions.isEmpty {
                        emptyActiveState
                    } else {
                        activeSuggestionContent
                    }
                }
            }
        }
        .navigationTitle("行动建议")
        .toolbar {
            if viewModel.isGenerating {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - 进度概览
    private var progressHeader: some View {
        let total = viewModel.suggestions.count
        let completed = viewModel.completedSuggestions.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0

        return HStack(spacing: 16) {
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.themeTextTertiary.opacity(0.2), lineWidth: 6)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.themeSecondary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.themeSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("完成进度")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Text("\(completed)/\(total) 项已完成")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.themeSurface)
    }

    // MARK: - 进行中的建议
    private var activeSuggestionContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 高优先级
                if !viewModel.highPriority.isEmpty {
                    prioritySection(title: "优先处理", icon: "exclamationmark.circle.fill", color: .themeError, items: viewModel.highPriority)
                }

                // 中优先级
                if !viewModel.mediumPriority.isEmpty {
                    prioritySection(title: "近期目标", icon: "target", color: .themeInfo, items: viewModel.mediumPriority)
                }

                // 低优先级
                if !viewModel.lowPriority.isEmpty {
                    prioritySection(title: "长期方向", icon: "compass.drawing", color: .themeTextTertiary, items: viewModel.lowPriority)
                }
            }
            .padding()
        }
    }

    private func prioritySection(title: String, icon: String, color: Color, items: [SuggestionEntity]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundColor(.themeTextTertiary)
            }

            ForEach(items, id: \.id) { suggestion in
                SuggestionCardView(suggestion: suggestion, viewModel: viewModel)
            }
        }
    }

    private func suggestionList(_ items: [SuggestionEntity]) -> some View {
        List {
            ForEach(items, id: \.id) { suggestion in
                SuggestionCardView(suggestion: suggestion, viewModel: viewModel)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - 空状态
    private var emptyActiveState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            Image(systemName: "lightbulb.slash")
                .font(.system(size: 50))
                .foregroundColor(.themeTextTertiary)

            Text("还没有行动建议")
                .font(.headline)
                .foregroundColor(.themeTextSecondary)

            Text("先完成特质分析，然后点击「生成行动建议」，\n获得个性化的行动指南")
                .font(.subheadline)
                .foregroundColor(.themeTextTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private var emptyCompletedState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.themeTextTertiary)

            Text("还没有完成的建议")
                .font(.headline)
                .foregroundColor(.themeTextSecondary)

            Spacer()
        }
    }
}
