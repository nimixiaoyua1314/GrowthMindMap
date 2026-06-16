import SwiftUI

struct ExperienceListView: View {
    @ObservedObject var viewModel: ExperienceViewModel
    @State private var showFilters = false
    @Environment(\.colorScheme) private var colorScheme
    private var surfaceColor: Color { colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface }

    var body: some View {
        ZStack {
            ZenColorScheme.background(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // 统计概览卡片
                statsHeader

                // 搜索和筛选栏
                searchAndFilterBar

                // 列表
                if viewModel.filteredExperiences.isEmpty {
                    emptyState
                } else {
                    experienceList
                }
            }
        }
        .navigationTitle("人生经历")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.isShowingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.themePrimary)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            ExperienceEditView(viewModel: viewModel, experience: nil)
        }
        .sheet(item: $viewModel.editingExperience) { entity in
            ExperienceEditView(viewModel: viewModel, experience: entity)
        }
    }

    // MARK: - 统计概览
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatBadge(icon: "tray.full.fill", value: "\(viewModel.stats.total)", label: "总经历", color: .themePrimary)
            StatBadge(icon: "star.fill", value: String(format: "%.1f", viewModel.stats.averageImpact), label: "平均影响", color: .themeSecondary)
            StatBadge(icon: "chart.bar.fill", value: viewModel.stats.topCategory, label: "主要领域", color: .themeAccent)
            StatBadge(icon: "clock.fill", value: "\(viewModel.stats.recentCount)", label: "近30天", color: .themeInfo)
        }
        .padding()
        .background(surfaceColor)
    }

    // MARK: - 搜索和筛选
    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.themeTextTertiary)
                    TextField("搜索经历...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(surfaceColor)
                .cornerRadius(12)

                Button {
                    withAnimation { showFilters.toggle() }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(viewModel.selectedCategory != nil ? ".fill" : "")")
                        .font(.title2)
                        .foregroundColor(viewModel.selectedCategory != nil ? .themePrimary : .themeTextSecondary)
                }
            }
            .padding(.horizontal)

            if showFilters {
                categoryFilterChips
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
        .background(Color.themeBackground)
    }

    // MARK: - 分类筛选
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "全部", isSelected: viewModel.selectedCategory == nil) {
                    withAnimation { viewModel.selectedCategory = nil }
                }

                ForEach(ExperienceCategory.allCases) { category in
                    FilterChip(label: category.rawValue, isSelected: viewModel.selectedCategory == category.rawValue) {
                        withAnimation { viewModel.selectedCategory = category.rawValue }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 列表
    private var experienceList: some View {
        List {
            ForEach(viewModel.filteredExperiences, id: \.id) { experience in
                ExperienceCardView(experience: experience)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .onTapGesture {
                        viewModel.editingExperience = experience
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteExperience(experience)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.fetchExperiences()
        }
    }

    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(.themeTextTertiary)

            Text(viewModel.experiences.isEmpty ? "还没有记录经历" : "没有匹配的记录")
                .font(.headline)
                .foregroundColor(.themeTextSecondary)

            if viewModel.experiences.isEmpty {
                Text("记录你的人生重要时刻，\n发现自己的成长轨迹")
                    .font(.subheadline)
                    .foregroundColor(.themeTextTertiary)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.isShowingAddSheet = true
                } label: {
                    Label("记录第一条经历", systemImage: "plus")
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

// MARK: - 子组件

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.themeTextPrimary)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundColor(.themeTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.themePrimary : Color.themeSurface)
                .foregroundColor(isSelected ? .white : .themeTextSecondary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themePrimary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}
