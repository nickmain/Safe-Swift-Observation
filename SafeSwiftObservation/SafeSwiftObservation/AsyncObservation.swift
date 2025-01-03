//
//  AsyncObservation.swift
//  sdfsdfsdfdsfdsf
//
//  Created by Nick Main on 2025-01-02.
//

import Foundation
import Observation

@MainActor
class AsyncObservation<Observed: AnyObject & Observable, PropType> {

    private weak var weakObserved: Observed?
    private let path: KeyPath<Observed, PropType>
    private var continuation: AsyncStream<PropType>.Continuation?

    private init(observed: Observed, path: KeyPath<Observed, PropType>, continuation: AsyncStream<PropType>.Continuation) {
        print("❇️ AsyncObservation init")
        self.weakObserved = observed
        self.path = path
        self.continuation = continuation
        continuation.onTermination = { [weak self] reason in
            print("💔 AyncObservation continuation.onTermination \(reason)")
            if reason == .cancelled {
                Task { @MainActor in
                    self?.weakObserved = nil
                    self?.continuation = nil
                }
            }
        }
    }

    private func observe() {
        let value = withObservationTracking {
            weakObserved?[keyPath: path]
        } onChange: {
            // skip a beat to fetch the updated value
            DispatchQueue.main.async {
                // Strong capture of self below keeps this AyncObservation alive until
                // the observed object is deinitialized
                if self.weakObserved != nil {
                    self.observe()
                }
            }
        }

        if let value {
            continuation?.yield(value)
        }
    }

    deinit {
        print("💔 AyncObservation deinit")
        continuation?.finish()
    }

    static func asyncStream(observing: Observed, path: KeyPath<Observed, PropType>
    ) -> AsyncStream<PropType> {
        AsyncStream { continuation in
            let observation = AsyncObservation(observed: observing,
                                               path: path,
                                               continuation: continuation)
            observation.observe()
        }
    }
}

extension Observable where Self: AnyObject {

    @MainActor
    func observation<PropType>(of path: KeyPath<Self, PropType>) -> AsyncStream<PropType> {
        AsyncObservation.asyncStream(observing: self, path: path)
    }
}
