import SwiftUI

struct DiaryEditView: View {
    @ObservedObject var viewModel: DiaryViewModel
    var diary: DiaryEntryEntity?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var surfaceColor: Color { colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface }

    @State private var content: String = ""
    @State private var date: Date = Date()

    var isEditing: Bool { diary != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 16) {
                    // 日期
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(surfaceColor)
                        .cornerRadius(12)

                    // 文字内容
                    TextEditor(text: $content)
                        .font(.body)
                        .padding(12)
                        .background(surfaceColor)
                        .cornerRadius(14)
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("写下你的想法...")
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
            .navigationTitle(isEditing ? "编辑日记" : "写日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let d = diary else { return }
        content = d.content
        date = d.date
    }

    private func save() {
        let text = content.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let autoTitle = String(text.prefix(20))

        if let d = diary {
            viewModel.updateDiary(
                d,
                title: autoTitle,
                content: text,
                date: date,
                mood: 3,
                tags: [],
                weatherIcon: "sun.max.fill"
            )
        } else {
            viewModel.createDiary(
                title: autoTitle,
                content: text,
                date: date,
                mood: 3,
                tags: [],
                weatherIcon: "sun.max.fill"
            )
        }
        dismiss()
    }
}
