//
//  SafeSwiftObservationApp.swift
//  SafeSwiftObservation
//
//  Created by Nick Main on 2025-01-02.
//

import SwiftUI

@main
struct SafeSwiftObservationApp: App {
    let viewModel = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
