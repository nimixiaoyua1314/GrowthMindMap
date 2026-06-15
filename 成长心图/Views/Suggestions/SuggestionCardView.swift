import SwiftUI

struct SuggestionCardView: View {
    let suggestion: SuggestionEntity
    @ObservedObject var viewModel: SuggestionViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 完成按钮
            Button {
                withAnimation(.spring()) {
                    viewModel.toggleCompletion(suggestion)
                }
            } label: {
                Image(systemName: suggestion.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(suggestion.isCompleted ? .moodGood : .themeTextTertiary)
            }

            // 内容
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(suggestion.isCompleted ? .themeTextTertiary : .themeTextPrimary)
                        .strikethrough(suggestion.isCompleted)

                    Spacer()

                    // 优先级标签
                    priorityBadge
                }

                Text(suggestion.descriptionText)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    // 分类
                    Label(suggestion.category, systemImage: categoryIcon)
                        .font(.caption2)
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.themePrimary.opacity(0.08))
                        .cornerRadius(6)

                    // 关联特质
                    if !suggestion.relatedTrait.isEmpty {
                        Text(suggestion.relatedTrait)
                            .font(.caption2)
                            .foregroundColor(.themeSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.themeSecondary.opacity(0.08))
                            .cornerRadius(6)
                    }

                    Spacer()

                    // 截止日期
                    if let deadline = suggestion.deadline {
                        Text(deadline.relativeDescription)
                            .font(.caption2)
                            .foregroundColor(deadline < Date() ? .themeError : .themeTextTertiary)
                    }
                }
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
        .opacity(suggestion.isCompleted ? 0.7 : 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.deleteSuggestion(suggestion)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(priorityColor)
                .frame(width: 6, height: 6)
            Text(priorityLabel)
                .font(.caption2)
                .foregroundColor(priorityColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(priorityColor.opacity(0.1))
        .cornerRadius(4)
    }

    private var priorityColor: Color {
        switch suggestion.priority {
        case 1: return .themeError
        case 2: return .themeInfo
        case 3: return .themeTextTertiary
        default: return .themeTextTertiary
        }
    }

    private var priorityLabel: String {
        switch suggestion.priority {
        case 1: return "高"
        case 2: return "中"
        case 3: return "低"
        default: return ""
        }
    }

    private var categoryIcon: String {
        SuggestionCategory.allCases.first(where: { $0.rawValue == suggestion.category })?.iconName ?? "lightbulb"
    }
}
