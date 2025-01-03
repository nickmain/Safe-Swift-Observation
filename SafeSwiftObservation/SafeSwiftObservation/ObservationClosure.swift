//
//  ObservationClosure.swift
//  sdfsdfsdfdsfdsf
//
//  Created by Nick Main on 2024-12-18.
//

import Foundation
import Observation

class ObservationWeakRef<T: AnyObject> {
    private weak var weakObject: T?

    init(_ object: T) {
        self.weakObject = object
    }

    func access<PropType>(_ path: KeyPath<T, PropType>) -> PropType? {
        weakObject?[keyPath: path]
    }

    deinit {
        print("💔 ObservationWeakRef deinit")
    }
}

extension Observable where Self: AnyObject {

    /// Observe a property of an Observable object.
    ///
    /// The observation lasts until the observed object is deinitialized. Note that
    /// the propertyHandler callback is strongly held by the observed object so be
    /// careful to use weak capture in any passed closure to avoid retain cycles
    /// involving the observed object.
    ///
    /// - Parameters:
    ///   - propertyPath: the keypath of the property to observe
    ///   - propertyHandler: the callback to receive changes to the property. This is
    ///                      called on the main thread and is called immediately with
    ///                      the current value.
    ///
    @MainActor
    func observe<PropertyType>(_ propertyPath: KeyPath<Self, PropertyType>, propertyHandler: @MainActor @escaping (PropertyType) -> Void) {

        // This ObservationWeakRef will be captured in observationLoop() and the nested
        // closures, which are then held by the macro-generated ObservationRegistrar
        // in the observed object. The observed object will only ever be held weakly here,
        // by the ObservationWeakRef. When the observed object is released elsewhere the
        // ObservationRegistrar will be released and everything here will be released.
        let weakRef = ObservationWeakRef(self)

        func observationLoop() {
            let value = withObservationTracking {
                weakRef.access(propertyPath)
            } onChange: {
                // skip a beat to fetch the updated value
                DispatchQueue.main.async { observationLoop() }
            }

            if let value {
                propertyHandler(value)
            }
        }

        observationLoop()
    }
}
