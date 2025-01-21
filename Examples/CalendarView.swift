//
//  CalendarView.swift
//  Examples
//
//  Created by Majid Jabrayilov on 07.02.25.
//
import SwiftUI

public struct CalendarView<DateView>: View where DateView: View {
    let interval: DateInterval
    let showHeaders: Bool
    let onHeaderAppear: (Date) -> Void
    let content: (Date) -> DateView

    @Environment(\.sizeCategory) private var contentSize
    @Environment(\.calendar) private var calendar
    @State private var months: [Date] = []
    @State private var days: [Date: [Date]] = [:]

    private var columns: [GridItem] {
        let spacing: CGFloat = contentSize.isAccessibilityCategory ? 2 : 8
        return Array(repeating: GridItem(spacing: spacing), count: 7)
    }
    
    public init(
        interval: DateInterval,
        showHeaders: Bool = false,
        onHeaderAppear: @escaping (Date) -> Void = { _ in },
        @ViewBuilder content: @escaping (Date) -> DateView
    ) {
        self.interval = interval
        self.showHeaders = showHeaders
        self.onHeaderAppear = onHeaderAppear
        self.content = content
    }

    public var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(months, id: \.self) { month in
                Section(header: header(for: month)) {
                    ForEach(days[month, default: []], id: \.self) { date in
                        if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                            content(date).id(date)
                        } else {
                            content(date).hidden()
                        }
                    }
                }
            }
        }
        .scrollTargetLayout()
        .onAppear {
            months = calendar.generateDates(
                inside: interval,
                matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
            )
            
            days = months.reduce(into: [:]) { current, month in
                guard
                    let monthInterval = calendar.dateInterval(of: .month, for: month),
                    let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
                    let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end)
                else { return }
                
                current[month] = calendar.generateDates(
                    inside: DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end),
                    matching: DateComponents(hour: 0, minute: 0, second: 0)
                )
            }
        }
    }

    private func header(for month: Date) -> some View {
        Group {
            if showHeaders {
                Text(month.formatted(.dateTime.month().year()))
                    .font(.title)
                    .padding()
            }
        }
        .onAppear { onHeaderAppear(month) }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(interval: .currentMonth, showHeaders: false, onHeaderAppear: { _ in }) { _ in
            Text("30")
                .padding(8)
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
}
