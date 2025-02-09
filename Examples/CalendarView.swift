//
//  CalendarView.swift
//  Examples
//
//  Created by Majid Jabrayilov on 07.02.25.
//
import SwiftUI

struct CalendarDateID: Hashable {
    let date: Date
    let belongsToMonth: Bool
}

// Function wrapper to make closures equatable by reference
final class FunctionWrapper<Input, Output> {
    let function: (Input) -> Output
    
    init(_ function: @escaping (Input) -> Output) {
        self.function = function
    }
    
    func callAsFunction(_ input: Input) -> Output {
        function(input)
    }
}

extension FunctionWrapper: Equatable {
    static func == (lhs: FunctionWrapper<Input, Output>, rhs: FunctionWrapper<Input, Output>) -> Bool {
        return lhs === rhs
    }
}

private struct BodyTracker: ViewModifier {
    let id: String
    
    func body(content: Content) -> some View {
        print("⚡️ Body called for \(id)")
        return content
    }
}

extension View {
    func trackBody(id: String) -> some View {
        modifier(BodyTracker(id: id))
    }
}

public struct CalendarView<DateView>: View, Equatable where DateView: View {
    let interval: DateInterval
    let showHeaders: Bool
    private let onHeaderAppear: FunctionWrapper<Date, Void>
    private let content: FunctionWrapper<Date, DateView>
    
    private let viewId = UUID().uuidString
    
    @Environment(\.sizeCategory) private var contentSize
    @Environment(\.calendar) private var calendar
    @State private var months: [Date] = []
    @State private var days: [Date: [CalendarDateID]] = [:]
    
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
//        print("📱 CalendarView init with id: \(UUID().uuidString)")
        self.interval = interval
        self.showHeaders = showHeaders
        self.onHeaderAppear = FunctionWrapper(onHeaderAppear)
        self.content = FunctionWrapper(content)
    }
    
    public static func == (lhs: CalendarView<DateView>, rhs: CalendarView<DateView>) -> Bool {
//        print("🔍 Equality check for CalendarView")
        return lhs.interval == rhs.interval &&
        lhs.showHeaders == rhs.showHeaders &&
        lhs.onHeaderAppear === rhs.onHeaderAppear &&
        lhs.content === rhs.content
    }
    
    public var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(months, id: \.self) { month in
                Section(header: header(for: month)) {
                    ForEach(days[month, default: []], id: \.self) { dateID in
                        VStack(spacing: 0) {
                            if dateID.belongsToMonth {
                                content(dateID.date)
                                    //.trackBody(id: "Content-\(dateID.date)")
                                    .onAppear {
//                                        print("🎬 onAppear for Content-\(dateID.date)")
                                    }
                                    .onDisappear {
//                                        print("🎬 onDisappear for Content-\(dateID.date)")
                                    }
                            } else {
                                content(dateID.date)
                                    .hidden()
                                    //.trackBody(id: "HiddenContent-\(dateID.date)")
                            }
                        }
                        //.trackBody(id: "Cell-\(dateID.date)") // ! this one makes things worse when @Observable state is used  
                    }
                }
                //.id(month)
               // .trackBody(id: "Section-\(month)")
            }
        }
        .scrollTargetLayout(isEnabled: true)
        .onAppear {
//            print("🎬 onAppear for CalendarView: \(viewId)")
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
                
                let datesInRange = calendar.generateDates(
                    inside: DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end),
                    matching: DateComponents(hour: 0, minute: 0, second: 0)
                )
                
                current[month] = datesInRange.map { date in
                    CalendarDateID(
                        date: date,
                        belongsToMonth: calendar.isDate(date, equalTo: month, toGranularity: .month)
                    )
                }
            }
        }
        .onDisappear {
//            print("🎭 onDisappear for CalendarView: \(viewId)")
        }
       // .trackBody(id: "CalendarView-\(viewId)")
    }
    
    @ViewBuilder
    private func header(for month: Date) -> some View {
        VStack {
            if showHeaders {
                Text(month.formatted(.dateTime.month().year()))
                    .font(.title)
                    .padding()
            }
        }
       // .trackBody(id: "Header-\(month)")
        .onAppear {
            onHeaderAppear(month)
        }
    }
}
