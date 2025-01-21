//
//  ContentView.swift
//  Examples
//
//  Created by Majid Jabrayilov on 21.01.25.
//
import Observation
import SwiftUI

@MainActor @Observable final class Store {
    var dailyAverages: [Date: Double] = [:]
    
    nonisolated func generate(for date: Date) async {
        guard let month = Calendar.current.dateInterval(of: .month, for: date) else {
            return
        }
        
        let dates = Calendar.current.generateDates(
            inside: month,
            matching: .init(hour: 0, minute: 0, second: 0)
        )
        
        let keysAndValues = dates.map { ($0, Double.random(in: 40...190)) }
        let newAverages = Dictionary(keysAndValues) { a, b in a }
        
        await MainActor.run {
            dailyAverages.merge(newAverages) { a, b in b }
        }
    }
}

struct ContentView: View {
    @Environment(\.calendar) private var calendar
    @State private var store = Store()
    @State private var position: Date?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            CalendarView(
                interval: .lastFiveYears,
                showHeaders: true,
                onHeaderAppear: fetch
            ) { date in
                DateView(date: date, average: store.dailyAverages[date])
                // TODO: magic solution
//                    .equatable()
            }
        }
        .scrollPosition(id: $position)
        .onAppear {
            if position == nil {
                position = calendar.startOfDay(for: .now)
            }
        }
    }
    
    private func fetch(_ date: Date) {
        Task {
            await store.generate(for: date)
        }
    }
}

struct DateView: View, Equatable {
    let date: Date
    let average: Double?
    
    var body: some View {
        // TODO: navigation link slow downs the rendering.
        // Remove it and run to see the difference.
        NavigationLink(value: date) {
            VStack {
                Text(verbatim: date.formatted(.dateTime.day()))
                RoundedRectangle(cornerRadius: 2)
                    .foregroundStyle((average ?? 0) > 60 ? .blue : .gray)
                    .frame(height: 8)
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
