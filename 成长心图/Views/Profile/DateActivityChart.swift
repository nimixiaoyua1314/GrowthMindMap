import SwiftUI

/// GitHub 贡献图风格 — 日期活动点阵。默认6周，点击展开全量
struct DateActivityChart: View {
    let dates: [Date]
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var cs

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    private let collapsedWeeks = 7  // ~1.5个月

    var body: some View {
        let allData = buildGrid(weeks: nil)
        let visibleData = isExpanded ? allData : buildGrid(weeks: collapsedWeeks)

        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "chart.dots.scatter").font(.caption).foregroundColor(.themeTextTertiary)
                    Text(isExpanded ? "活动热力图（全部）" : "活动热力图").font(.subheadline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                    Spacer()
                    Text("\(allData.totalEntries) 条").font(.caption2).foregroundColor(.themeTextTertiary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.caption2).foregroundColor(.themeTextTertiary)
                }
            }.buttonStyle(.plain)

            HStack(spacing: 4) {
                Text("少").font(.system(size: 8)).foregroundColor(.themeTextTertiary)
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2).fill(activityColor(level: i, max: 4)).frame(width: 10, height: 10)
                }
                Text("多").font(.system(size: 8)).foregroundColor(.themeTextTertiary)
                if !isExpanded { Text("· 点击展开全部").font(.system(size: 8)).foregroundColor(ZenColor.gold.opacity(0.6)) }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: cellSpacing) {
                    HStack(spacing: cellSpacing) {
                        ForEach(visibleData.columns.indices, id: \.self) { c in
                            if c == 0 {
                                monthLabels(data: visibleData)
                            } else if let d = visibleData.columns[c] {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(activityColor(level: d.count, max: visibleData.maxCount))
                                    .frame(width: cellSize, height: cellSize)
                            } else {
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                    ForEach(0..<7, id: \.self) { row in
                        HStack(spacing: cellSpacing) {
                            ForEach(visibleData.columns.indices, id: \.self) { c in
                                if c == 0 {
                                    Text(visibleData.weekdayLabels[row]).font(.system(size: 7)).foregroundColor(.themeTextTertiary).frame(width: cellSize, height: cellSize)
                                } else if let d = visibleData.columns[c], d.dayOfWeek == row {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(activityColor(level: d.count, max: visibleData.maxCount))
                                        .frame(width: cellSize, height: cellSize)
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(cs == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }.padding(.vertical, 4)
            }.animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .padding()
        .background(cs == .dark ? ZenColor.darkSurface : Color.themeSurface)
        .cornerRadius(14)
    }

    // MARK: - Data
    struct DayData { let date: Date; let count: Int; let dayOfWeek: Int }
    struct GridData { let columns: [DayData?]; let maxCount: Int; let totalEntries: Int; let weekdayLabels: [String] }

    private func buildGrid(weeks: Int?) -> GridData {
        let cal = Calendar.current
        let today = Date()
        let startDate: Date
        if let w = weeks {
            startDate = cal.date(byAdding: .day, value: -(w * 7), to: today)!
        } else {
            let earliest = dates.min() ?? today
            startDate = cal.startOfDay(for: earliest)
        }

        var dayCounts: [Date: Int] = [:]
        for d in dates { dayCounts[cal.startOfDay(for: d), default: 0] += 1 }

        var columns: [DayData?] = [nil]
        var current = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: today)
        let firstWd = cal.component(.weekday, from: current) - 1
        for _ in 0..<firstWd { columns.append(nil) }

        while current <= end {
            let cnt = dayCounts[current] ?? 0
            let wd = cal.component(.weekday, from: current) - 1
            columns.append(DayData(date: current, count: cnt, dayOfWeek: wd))
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }

        let maxC = max(dayCounts.values.max() ?? 1, 1)
        let total = dayCounts.values.reduce(0, +)
        return GridData(columns: columns, maxCount: maxC, totalEntries: total, weekdayLabels: ["日","一","二","三","四","五","六"])
    }

    private func monthLabels(data: GridData) -> some View {
        let cal = Calendar.current
        var labels: [(String, Int)] = []
        var lastM = -1
        for (i, c) in data.columns.enumerated() {
            guard let d = c else { continue }
            let m = cal.component(.month, from: d.date)
            if m != lastM { labels.append((cal.shortMonthSymbols[m-1], i)); lastM = m }
        }
        return ZStack {
            ForEach(labels.indices, id: \.self) { i in
                Text(labels[i].0).font(.system(size: 7)).foregroundColor(.themeTextTertiary)
                    .offset(x: CGFloat(labels[i].1) * (cellSize + cellSpacing))
            }
        }.frame(width: CGFloat(data.columns.count) * (cellSize + cellSpacing), height: cellSize, alignment: .leading).clipped()
    }

    private func activityColor(level: Int, max: Int) -> Color {
        guard max > 0 else { return cs == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05) }
        switch CGFloat(level) / CGFloat(max) {
        case 0: return cs == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
        case ..<0.25: return ZenColor.jadePale.opacity(0.5)
        case ..<0.5:  return ZenColor.jade.opacity(0.6)
        case ..<0.75: return ZenColor.jade.opacity(0.8)
        default:      return ZenColor.gold.opacity(0.85)
        }
    }
}
