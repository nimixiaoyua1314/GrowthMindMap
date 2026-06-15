import SwiftUI

struct DiaryListView: View {
    @ObservedObject var viewModel: DiaryViewModel
    @State private var showCalendar = false
    @State private var isShowingEditor = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // 心情统计
                moodStatsHeader

                // 搜索和日历切换
                searchBar

                // 日历（可折叠）
                if showCalendar {
                    calendarView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 日记列表
                if viewModel.filteredDiaries.isEmpty {
                    emptyState
                } else {
                    diaryList
                }
            }
        }
        .navigationTitle("日记")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingEditor = true
                } label: {
                    Image(systemName: "square.and.pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.themePrimary)
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            DiaryEditView(viewModel: viewModel, diary: nil)
        }
        .sheet(item: $viewModel.editingDiary) { entity in
            DiaryEditView(viewModel: viewModel, diary: entity)
        }
    }

    // MARK: - 心情统计
    private var moodStatsHeader: some View {
        HStack(spacing: 16) {
            StatBadge(icon: "face.smiling.fill", value: String(format: "%.1f", viewModel.moodStats.averageMood), label: "平均心情", color: .moodGood)
            StatBadge(icon: "pencil.and.list.clipboard", value: "\(viewModel.moodStats.totalEntries)", label: "总日记", color: .themePrimary)
            StatBadge(icon: "calendar.badge.checkmark", value: "\(viewModel.moodStats.totalDays)", label: "写作天数", color: .themeInfo)
            StatBadge(icon: "flame.fill", value: "\(viewModel.moodStats.maxStreak)天", label: "最长连续", color: .moodExcellent)
        }
        .padding()
        .background(Color.themeSurface)
    }

    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.themeTextTertiary)
                TextField("搜索日记...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.themeSurface)
            .cornerRadius(12)

            Button {
                withAnimation(.spring()) {
                    showCalendar.toggle()
                    if !showCalendar {
                        viewModel.selectedDate = nil
                    }
                }
            } label: {
                Image(systemName: showCalendar ? "calendar.circle.fill" : "calendar.circle")
                    .font(.title2)
                    .foregroundColor(showCalendar ? .themePrimary : .themeTextSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 日历视图
    private var calendarView: some View {
        DiaryCalendarView(
            diaryDates: viewModel.diaryDates,
            selectedDate: $viewModel.selectedDate,
            onDateTapped: { date in
                viewModel.selectedDate = date
            }
        )
        .padding()
        .background(Color.themeSurface)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - 日记列表
    private var diaryList: some View {
        List {
            ForEach(viewModel.filteredDiaries, id: \.id) { diary in
                DiaryCardView(diary: diary)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .onTapGesture {
                        viewModel.editingDiary = diary
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteDiary(diary)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.fetchDiaries()
        }
    }

    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 50))
                .foregroundColor(.themeTextTertiary)

            Text(viewModel.diaries.isEmpty ? "还没有写日记" : "没有匹配的日记")
                .font(.headline)
                .foregroundColor(.themeTextSecondary)

            if viewModel.diaries.isEmpty {
                Text("每天花几分钟记录你的想法，\n这是与自己对话的珍贵时刻")
                    .font(.subheadline)
                    .foregroundColor(.themeTextTertiary)
                    .multilineTextAlignment(.center)

                Button {
                    isShowingEditor = true
                } label: {
                    Label("写下第一篇日记", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.themePrimary)
                        .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - 日记卡片
struct DiaryCardView: View {
    let diary: DiaryEntryEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(diary.date.chineseFormat)
                    .font(.caption)
                    .foregroundColor(.themeTextTertiary)

                Spacer()

                // 心情
                HStack(spacing: 2) {
                    Image(systemName: moodIcon)
                        .foregroundColor(moodColor)
                    Text(moodLabel)
                        .font(.caption)
                        .foregroundColor(moodColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(moodColor.opacity(0.12))
                .cornerRadius(6)

                // 天气
                Image(systemName: diary.weatherIcon)
                    .font(.caption)
                    .foregroundColor(.themeTextTertiary)
            }

            Text(diary.title)
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
                .lineLimit(1)

            Text(diary.content)
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
                .lineLimit(3)

            if !diary.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(diary.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.themePrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.themePrimary.opacity(0.08))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeSurface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var moodIcon: String {
        switch diary.mood {
        case 5: return "face.smiling.fill"
        case 4: return "face.smiling"
        case 3: return "face.neutral"
        case 2: return "face.smiling"
        case 1: return "face.dashed"
        default: return "face.neutral"
        }
    }

    private var moodLabel: String {
        switch diary.mood {
        case 5: return "很好"
        case 4: return "不错"
        case 3: return "一般"
        case 2: return "不好"
        case 1: return "很差"
        default: return "一般"
        }
    }

    private var moodColor: Color {
        switch diary.mood {
        case 5: return .moodExcellent
        case 4: return .moodGood
        case 3: return .moodNeutral
        case 2: return .moodBad
        case 1: return .moodTerrible
        default: return .moodNeutral
        }
    }
}
