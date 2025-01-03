//
//  ContentView.swift
//  sdfsdfsdfdsfdsf
//
//  Created by Nick Main on 2024-12-17.
//

import Observation
import SwiftUI

@Observable
@MainActor
class ReceiverModel {
    var text1 = "Hello - no Observed set - press Remodel Observed"
    var text2 = "Hello AsyncObservation"
    var text3 = "Hello ObservationClosure"
    var count = 1 {
        didSet { print("🩵 ReceiverModel count = '\(count)'") }
    }

    private var observedText: String? {
        get { nil }
        set {
            print("🩵 ReceiverModel observedText = '\(newValue ?? "<nil>")'")
            text1 = "Hello, \(newValue ?? "<no Observed model>")"
        }
    }

    @ObservationIgnored
    private var observedModel: ObservedModel? {
        didSet {
            if let observedModel {
                observedModel.bridge(\.text1, to: self, \.observedText)
                observedModel.bridge(\.count, to: self, \.count)

                // Note that [weak self] is required below to avoid a retain
                // cycle since the closure is strongly referenced by the observedModel
                // observation registrar.
                observedModel.observe(\.text3) { [weak self] in
                    self?.text3 = "Hello, \($0)"
                }

                // Note that the Task will capture self or observedModel and cause
                // retain cycles unless these precautions are used...
                let asyncObservation = observedModel.observation(of: \.text2)
                Task { [weak self] in
                    for await textValue in asyncObservation {
                        print("💛 async stream received '\(textValue)'")
                        self?.text2 = "Hello, \(textValue)"
                    }
                }
            }
        }
    }

    func doSomething() {
        observedModel?.doSomething()
    }

    func nukeObservedModel() {
        observedModel = nil
    }

    func remodelObservedModel() {
        observedModel = ObservedModel()
    }

    deinit { print("💔 ReceiverModel deinit") }
}

@Observable
@MainActor
class ObservedModel {
    var text1 = "Initial State 1"
    var text2 = "Initial State 2"
    var text3 = "Initial State 3"
    var count = 10

    func doSomething() {
        count += 1
        text1 = "ObservationBridge \(count)"
        text2 = "AsyncObservation \(count)"
        text3 = "ObservationClosure \(count)"
    }

    deinit { print("💔 ObservedModel deinit") }
}

@Observable
@MainActor
class ViewModel {
    var model = ReceiverModel()

    func remodelReceiverModel() {
        model = ReceiverModel()
    }
}

struct ContentView: View {
    let viewModel: ViewModel

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(viewModel.model.text1)
            Text(viewModel.model.text2)
            Text(viewModel.model.text3)
            Text("Count: \(viewModel.model.count)")
            Spacer()
            Button("Do it") {
                viewModel.model.doSomething()
            }
            Button("Nuke Observed") {
                viewModel.model.nukeObservedModel()
            }
            Button("Remodel Observed") {
                viewModel.model.remodelObservedModel()
            }
            Button("Remodel Receiver") {
                viewModel.remodelReceiverModel()
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView(viewModel: ViewModel())
}
