//
//  ContentView.swift
//  Examples
//
//  Created by Majid Jabrayilov on 21.01.25.
//
import Observation
import SwiftUI
import Combine

@MainActor final class Store2: ObservableObject {
    private var pipelines: Set<AnyCancellable> = []
    @Published var path = NavigationPath()
    @Published var dailyAverages: [Date: Double] = [:]
    private var positionStore: CalendarDateID?
    
    var __position: Binding<CalendarDateID?> {
        Binding { [weak self] in
            print("store.__position get: \(String(describing: self?.positionStore))")
            return self?.positionStore
        } set: { [weak self] date, transaction in
            guard let self else { return }
            guard date?.belongsToMonth == true else { return }
            guard self.positionStore != date else { return }
            self.objectWillChange.send()
            withTransaction(transaction) {
                self.positionStore = date
            }
            print("store.__position set: \(String(describing: date))")
            //            self.positionSub.send((date, transaction))
        }
        
    }
    
    func selectDate(_ date: Date) {
        path.append(date)
    }
    
    /*
     // does not work as expected
     public let positionSub = PassthroughSubject<(CalendarDateID?, Transaction), Never>()
     public var positionPub: AnyPublisher<(CalendarDateID?, Transaction), Never> {
     positionSub
     .eraseToAnyPublisher()
     }
     
     init() {
     initPipelines()
     }
     
     func initPipelines() {
     positionPub
     .throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
     .debounce(for: 1, scheduler: RunLoop.main)
     .receive(on: RunLoop.main)
     .sink { [weak self] position, transaction in
     print("store.__position set: objectWillChange")
     withTransaction(transaction) {
     self?.positionStore = position
     }
     self?.objectWillChange.send()
     }
     .store(in: &pipelines)
     
     */
    
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
    //    @State private var store = Store()
    @ObservedObject private var store: Store2
    
    init(store: Store2) {
        self.store = store
    }
    //    @State private var position: CalendarDateID?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            CalendarView(
                interval: .lastFiveYears,
                showHeaders: true,
                onHeaderAppear: fetch
            ) { date in
                DateView2(date: date, average: store.dailyAverages[date], onSelect: .init(store.selectDate(_:)))
                //                        .equatable()
            }
            //                .equatable()
            
        }
        .navigationDestination(for: Date.self) { date in
            DateDetailView(
                date: date,
                average: store.dailyAverages[date]
            )
        }
//        .scrollPosition(id: store.__position)
//        .toolbar {
//            Button("Today") {
//                withAnimation {
//                    store.__position.wrappedValue = CalendarDateID(date: calendar.startOfDay(for: .now), belongsToMonth: true)
//                }
//            }
//        }
        .onAppear {
            //            if store.__position.wrappedValue == nil {
            //                store.__position.wrappedValue = CalendarDateID(date: calendar.startOfDay(for: .now), belongsToMonth: true)
            //            }
        }
        //        .onChange(of: position) { _, position in
        //            if let date = position?.date {
        //                print("scrollPosition: \(date)")
        //            }
        //        }
    }
    
    private func fetch(_ date: Date) {
        Task {
            //            await store.generate(for: date)
        }
    }
}

struct DateView: View, Equatable {
    let date: Date
    let average: Double?
    
    var body: some View {
        // TODO: navigation link slow downs the rendering. (actually, any button will have similar behavior)
        // Remove it and run to see the difference.
        //  NavigationLink(value: date) {
        VStack {
            Text(verbatim: date.formatted(.dateTime.day()))
            RoundedRectangle(cornerRadius: 2)
                .foregroundStyle((average ?? 0) > 60 ? .blue : .gray)
                .frame(height: 8)
        }
        //   }
    }
}

struct DateView2: View, Equatable {
    let date: Date
    let average: Double?
    let onSelect: FunctionWrapper<Date, Void>
    
    var body: some View {
        VStack {
            Text(verbatim: date.formatted(.dateTime.day()))
            RoundedRectangle(cornerRadius: 2)
                .foregroundStyle((average ?? 0) > 60 ? .blue : .gray)
                .frame(height: 8)
        }
        .onTapGesture {
            onSelect(date)
        }
    }
}

struct DateDetailView: View {
    let date: Date
    let average: Double?
    
    var body: some View {
        VStack {
            Text(date.formatted(.dateTime.year().month().day()))
                .font(.title)
            
            if let average {
                Text("Average: \(average, specifier: "%.1f")")
                    .font(.headline)
            } else {
                Text("No data available")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Details")
    }
}

