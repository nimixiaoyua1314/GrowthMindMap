import SwiftUI

struct ExperienceEditView: View {
    @ObservedObject var viewModel: ExperienceViewModel
    var experience: ExperienceEntity?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var surfaceColor: Color { colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface }

    @State private var detailText: String = ""
    @State private var date: Date = Date()
    @State private var category: String = "其他"

    var isEditing: Bool { experience != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 16) {
                    // 日期 + 分类 并排
                    HStack(spacing: 12) {
                        // 日期
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(12)
                            .background(surfaceColor)
                            .cornerRadius(12)

                        // 分类
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ExperienceCategory.allCases) { cat in
                                    Button {
                                        category = cat.rawValue
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: cat.iconName)
                                                .font(.caption)
                                            Text(cat.rawValue)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(category == cat.rawValue ? Color(hex: cat.color).opacity(0.15) : Color.themeSurface)
                                        .foregroundColor(category == cat.rawValue ? Color(hex: cat.color) : .themeTextSecondary)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(category == cat.rawValue ? Color(hex: cat.color) : .clear, lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // 文字内容 — 核心
                    TextEditor(text: $detailText)
                        .font(.body)
                        .padding(12)
                        .background(surfaceColor)
                        .cornerRadius(14)
                        .overlay(
                            Group {
                                if detailText.isEmpty {
                                    Text("记录这段经历...")
                                        .foregroundColor(.themeTextTertiary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                        .frame(maxHeight: .infinity)
                }
                .padding()
            }
            .navigationTitle(isEditing ? "编辑经历" : "记录经历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(detailText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let exp = experience else { return }
        detailText = exp.detailText
        date = exp.date
        category = exp.category
    }

    private func save() {
        let text = detailText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        // title 自动取前20字
        let autoTitle = String(text.prefix(20))

        if let exp = experience {
            viewModel.updateExperience(
                exp,
                title: autoTitle,
                detailText: text,
                date: date,
                category: category,
                emotionTags: [],
                impactLevel: 3,
                lifeLessons: ""
            )
        } else {
            viewModel.createExperience(
                title: autoTitle,
                detailText: text,
                date: date,
                category: category,
                emotionTags: [],
                impactLevel: 3,
                lifeLessons: ""
            )
        }
        dismiss()
    }
}
