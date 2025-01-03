//
//  ObservationProxy.swift
//  sdfsdfsdfdsfdsf
//
//  Created by Nick Main on 2025-01-01.
//

import Foundation
import Observation

@MainActor
class ObservationBridge<Observed: AnyObject & Observable, Receiver: AnyObject, PropType> {

    enum ReceiverPath {
        case optional(WritableKeyPath<Receiver, PropType?>)
        case nonOptional(WritableKeyPath<Receiver, PropType>)
    }

    private weak var weakObserved: Observed?
    private weak var weakReceiver: Receiver?
    private let sourcePath: KeyPath<Observed, PropType>
    private let receiverPath: ReceiverPath

    private init(observed: Observed, receiver: Receiver, sourcePath: KeyPath<Observed, PropType>, receiverPath: ReceiverPath) {
        print("❇️ ObservationBridge init")
        self.weakObserved = observed
        self.weakReceiver = receiver
        self.sourcePath = sourcePath
        self.receiverPath = receiverPath
    }

    private func observe() {
        let value = withObservationTracking {
            weakObserved?[keyPath: sourcePath]
        } onChange: {
            // skip a beat to fetch the updated value
            DispatchQueue.main.async {
                // Strong capture of self below keeps this ObservationBridge alive until
                // the observed object is deinitialized
                if self.weakObserved != nil && self.weakReceiver != nil {
                    self.observe()
                }
            }
        }

        if let value {
            switch receiverPath {
            case .nonOptional(let path):
                weakReceiver?[keyPath: path] = value
            case .optional(let path):
                weakReceiver?[keyPath: path] = value
            }
        }
    }

    deinit {
        print("💔 ObservationBridge deinit")

        switch receiverPath {
        case .nonOptional:
            break
        case .optional(let path):
            weakReceiver?[keyPath: path] = nil
        }
    }

    static func start(observed: Observed,
                      receiver: Receiver,
                      sourcePath: KeyPath<Observed, PropType>,
                      receiverPath: ReceiverPath) {
        let bridge = ObservationBridge(observed: observed,
                                       receiver: receiver,
                                       sourcePath: sourcePath,
                                       receiverPath: receiverPath)
        bridge.observe()
    }
}

extension Observable where Self: AnyObject {

    /// Observe a property of an Observable object (self) and pass changes
    /// to a property on a receiving object.
    ///
    /// Properties will be read and written to on the main actor.
    ///
    /// The observed and receiving objects are held weakly and the bridging
    /// will continue until one of the objects is deinitialized. Key paths are
    /// used to avoid unintended retain cycles.
    ///
    /// - Parameters:
    ///   - sourcePath: the property to observe
    ///   - receiver: the object that receives property changes
    ///   - targetPath: the receiver property to update
    ///
    @MainActor
    func bridge<Receiver: AnyObject, PropType>(_ sourcePath: KeyPath<Self, PropType>, to receiver: Receiver, _ targetPath: WritableKeyPath<Receiver, PropType>) {
        ObservationBridge.start(observed: self, receiver: receiver, sourcePath: sourcePath, receiverPath: .nonOptional(targetPath))
    }

    /// Observe a property of an Observable object (self) and pass changes
    /// to an optional property on a receiving object.
    ///
    /// When the observed object is deinitialized the receiving property
    /// will be set to nil.
    ///
    /// Properties will be read and written to on the main actor.
    ///
    /// The observed and receiving objects are held weakly and the bridging
    /// will continue until one of the objects is deinitialized. Key paths are
    /// used to avoid unintended retain cycles.
    ///
    /// - Parameters:
    ///   - sourcePath: the property to observe
    ///   - receiver: the object that receives property changes
    ///   - targetPath: the optional receiver property to update
    ///
    @MainActor
    func bridge<Receiver: AnyObject, PropType>(_ sourcePath: KeyPath<Self, PropType>, to receiver: Receiver, _ targetPath: WritableKeyPath<Receiver, PropType?>) {
        ObservationBridge.start(observed: self, receiver: receiver, sourcePath: sourcePath, receiverPath: .optional(targetPath))
    }
}
