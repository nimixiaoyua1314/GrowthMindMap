import SwiftUI

struct DiaryCalendarView: View {
    let diaryDates: Set<Date>
    @Binding var selectedDate: Date?
    let onDateTapped: (Date) -> Void

    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 12) {
            // 月份切换
            HStack {
                Button {
                    withAnimation { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)! }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.themePrimary)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)

                Spacer()

                Button {
                    withAnimation { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)! }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.themePrimary)
                }
            }

            // 星期
            HStack {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.themeTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日期格
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    let isInMonth = date != nil && calendar.isDate(date!, equalTo: currentMonth, toGranularity: .month)
                    let hasDiary = date != nil && diaryDates.contains(calendar.startOfDay(for: date!))
                    let isSelected = date != nil && selectedDate != nil && calendar.isDate(date!, inSameDayAs: selectedDate!)
                    let isToday = date != nil && calendar.isDateInToday(date!)

                    if let date = date, isInMonth {
                        Button {
                            selectedDate = isSelected ? nil : date
                            onDateTapped(date)
                        } label: {
                            ZStack {
                                if isToday {
                                    Circle()
                                        .fill(Color.themePrimary.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                }

                                if isSelected {
                                    Circle()
                                        .fill(Color.themePrimary)
                                        .frame(width: 32, height: 32)
                                }

                                Text("\(calendar.component(.day, from: date))")
                                    .font(.caption)
                                    .fontWeight(isToday || isSelected ? .bold : .regular)
                                    .foregroundColor(
                                        isSelected ? .white :
                                        isToday ? .themePrimary :
                                        isInMonth ? .themeTextPrimary : .clear
                                    )

                                if hasDiary {
                                    Circle()
                                        .fill(Color.themeSecondary)
                                        .frame(width: 5, height: 5)
                                        .offset(y: 14)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: startOfMonth))
        }
        // 补齐到最后一周
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }
}
