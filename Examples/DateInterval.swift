//
//  DateInterval.swift
//  Examples
//
//  Created by Majid Jabrayilov on 07.02.25.
//


import Foundation

extension DateInterval {
    public static func trendInterval(for date: Date) -> DateInterval {
        let end = Calendar.current.startOfDay(for: date)
        return DateInterval(start: end.addingTimeInterval(-30 * 24 * 3600), end: end)
    }

    public static func twoWeeksAgo(from date: Date) -> DateInterval {
        DateInterval(start: date.addingTimeInterval(-14 * 24 * 3600), end: date)
    }

    public static var today: DateInterval {
        Calendar.current.dateInterval(of: .day, for: Date()) ?? .init()
    }

    public static var lastFiveYears: DateInterval = {
        guard
            let yearAgo = Calendar.current.date(byAdding: .year, value: -5, to: Date()),
            let firstMonthInterval = Calendar.current.dateInterval(of: .month, for: yearAgo)
        else { return .init() }
        return DateInterval(start: firstMonthInterval.start, end: currentMonth.end)
    }()

    public static var lastTwoMonths: DateInterval {
        guard
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            let lastMonthInterval = Calendar.current.dateInterval(of: .month, for: lastMonth)
        else { return .init() }
        return DateInterval(start: lastMonthInterval.start, end: currentMonth.end)
    }

    public static var currentMonth: DateInterval {
        Calendar.current.dateInterval(of: .month, for: Date()) ?? .init()
    }

    public var days: Int {
        let days = duration / TimeInterval(24 * 3600)
        return Int(days.rounded(.up))
    }
}
