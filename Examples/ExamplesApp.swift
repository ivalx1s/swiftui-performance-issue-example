//
//  ExamplesApp.swift
//  Examples
//
//  Created by Majid Jabrayilov on 21.01.25.
//

import SwiftUI

@main
struct ExamplesApp: App {
    
    @StateObject private var store = Store2()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $store.path) {
                ContentView(store: store)
            }
        }
    }
}
