import SwiftUI

struct ExperienceCardView: View {
    let experience: ExperienceEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：分类 + 日期
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon)
                        .font(.caption)
                    Text(experience.category)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(categoryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(categoryColor.opacity(0.12))
                .cornerRadius(8)

                Spacer()

                Text(experience.date.relativeDescription)
                    .font(.caption)
                    .foregroundColor(.themeTextTertiary)
            }

            // 标题
            Text(experience.title)
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
                .lineLimit(2)

            // 描述
            if !experience.detailText.isEmpty {
                Text(experience.detailText)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
                    .lineLimit(3)
            }

            // 底部：情绪标签 + 影响度
            HStack(spacing: 8) {
                // 情绪标签
                ForEach(experience.emotionTags.prefix(3), id: \.self) { tag in
                    if let emotion = EmotionTag.allCases.first(where: { $0.rawValue == tag }) {
                        Text("\(emotion.emoji) \(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.themePrimary.opacity(0.08))
                            .cornerRadius(6)
                    }
                }

                if experience.emotionTags.count > 3 {
                    Text("+\(experience.emotionTags.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.themeTextTertiary)
                }

                Spacer()

                // 影响程度
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(i <= experience.impactLevel ? .themeSecondary : .themeTextTertiary.opacity(0.3))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeSurface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var categoryIcon: String {
        ExperienceCategory.allCases.first(where: { $0.rawValue == experience.category })?.iconName ?? "circle.fill"
    }

    private var categoryColor: Color {
        if let cat = ExperienceCategory.allCases.first(where: { $0.rawValue == experience.category }) {
            return Color(hex: cat.color)
        }
        return .themePrimary
    }
}
