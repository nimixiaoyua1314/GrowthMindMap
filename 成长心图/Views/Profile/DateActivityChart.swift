import SwiftUI

/// GitHub 贡献图风格 — 日期活动点阵
struct DateActivityChart: View {
    let dates: [Date]              // 所有记录的日期
    let months: Int = 6            // 展示最近几个月

    @Environment(\.colorScheme) private var cs

    private let cellSize: CGFloat = 13
    private let cellSpacing: CGFloat = 3
    private let daysInWeek = 7

    var body: some View {
        let data = buildGrid()

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "chart.dots.scatter")
                    .font(.caption).foregroundColor(.themeTextTertiary)
                Text("活动热力图")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                Text("\(data.totalEntries) 条记录")
                    .font(.caption2).foregroundColor(.themeTextTertiary)
            }

            // 图例
            HStack(spacing: 4) {
                Text("少").font(.system(size: 8)).foregroundColor(.themeTextTertiary)
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(activityColor(level: i, max: 4))
                        .frame(width: 10, height: 10)
                }
                Text("多").font(.system(size: 8)).foregroundColor(.themeTextTertiary)
            }

            // 点阵
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: cellSpacing) {
                    // 星期标签
                    HStack(spacing: cellSpacing) {
                        ForEach(data.columns.indices, id: \.self) { colIdx in
                            if colIdx == 0 {
                                // Month labels on first row
                                monthLabels(data: data)
                            } else {
                                let dayData = data.columns[colIdx]
                                if let d = dayData {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(activityColor(level: d.count, max: data.maxCount))
                                        .frame(width: cellSize, height: cellSize)
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.clear)
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }

                    // Day rows
                    ForEach(0..<daysInWeek, id: \.self) { row in
                        HStack(spacing: cellSpacing) {
                            ForEach(data.columns.indices, id: \.self) { colIdx in
                                if colIdx == 0 {
                                    // Weekday label
                                    Text(data.weekdayLabels[row])
                                        .font(.system(size: 7))
                                        .foregroundColor(.themeTextTertiary)
                                        .frame(width: cellSize, height: cellSize)
                                } else {
                                    let dayData = data.columns[colIdx]
                                    if let d = dayData, d.dayOfWeek == row {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(activityColor(level: d.count, max: data.maxCount))
                                            .frame(width: cellSize, height: cellSize)
                                    } else {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(cs == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface)
        .cornerRadius(14)
    }

    // MARK: - 数据

    struct DayData {
        let date: Date
        let count: Int
        let dayOfWeek: Int  // 0=Sun
    }

    struct GridData {
        let columns: [DayData?]
        let maxCount: Int
        let totalEntries: Int
        let weekdayLabels: [String]
    }

    private func buildGrid() -> GridData {
        let cal = Calendar.current
        let today = Date()
        let startDate = cal.date(byAdding: .month, value: -months, to: today)!

        // Count entries per day
        var dayCounts: [Date: Int] = [:]
        for d in dates {
            let day = cal.startOfDay(for: d)
            dayCounts[day, default: 0] += 1
        }

        // Build columns
        var columns: [DayData?] = [nil] // First is label column
        var currentDate = cal.startOfDay(for: startDate)
        let endDate = cal.startOfDay(for: today)

        // Align to Sunday
        let firstWeekday = cal.component(.weekday, from: currentDate) - 1
        for _ in 0..<firstWeekday {
            columns.append(nil)
        }

        while currentDate <= endDate {
            let count = dayCounts[currentDate] ?? 0
            let weekday = cal.component(.weekday, from: currentDate) - 1
            columns.append(DayData(date: currentDate, count: count, dayOfWeek: weekday))
            currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
        }

        let maxCount = max(dayCounts.values.max() ?? 1, 1)
        let total = dayCounts.values.reduce(0, +)
        let labels = ["日", "一", "二", "三", "四", "五", "六"]

        return GridData(columns: columns, maxCount: maxCount, totalEntries: total, weekdayLabels: labels)
    }

    // MARK: - 月份标签
    private func monthLabels(data: GridData) -> some View {
        let cal = Calendar.current
        var labels: [(String, Int)] = []
        var lastMonth = -1

        for (idx, col) in data.columns.enumerated() {
            guard let d = col else { continue }
            let m = cal.component(.month, from: d.date)
            if m != lastMonth {
                labels.append((cal.shortMonthSymbols[m - 1], idx))
                lastMonth = m
            }
        }

        return ZStack {
            ForEach(labels.indices, id: \.self) { i in
                Text(labels[i].0)
                    .font(.system(size: 7))
                    .foregroundColor(.themeTextTertiary)
                    .offset(x: CGFloat(labels[i].1) * (cellSize + cellSpacing))
            }
        }
        .frame(width: CGFloat(data.columns.count) * (cellSize + cellSpacing), height: cellSize, alignment: .leading)
        .clipped()
    }

    // MARK: - 颜色
    private func activityColor(level: Int, max: Int) -> Color {
        guard max > 0 else { return cs == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06) }
        let ratio = CGFloat(level) / CGFloat(max)
        switch ratio {
        case 0:     return cs == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
        case ..<0.25: return ZenColor.jadePale.opacity(0.5)
        case ..<0.5:  return ZenColor.jade.opacity(0.6)
        case ..<0.75: return ZenColor.jade.opacity(0.8)
        default:      return ZenColor.gold.opacity(0.85)
        }
    }
}
