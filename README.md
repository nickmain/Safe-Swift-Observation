# Safe-Swift-Observation

Experiments in using Swift Observation outside of SwiftUI.

The motivating problem involves a view-model and a sub-view-model.
The view-model has a reference to the sub-view-model and needs to observe
one or more properties of that.

Using Swift Observation is tricky since it is easy to create a retain cycle between
the two objects by strongly capturing either one in the onChange closure that is
kept in the (macro generated) observation registrar of the sub-view-model.

Three approaches are

* using an AsyncStream to receive property updates. See [Create an AsyncStream from withObservationTracking() function](https://nilcoalescing.com/blog/AsyncStreamFromWithObservationTrackingFunc/)
* observing via a key path and a handler closure
* observing a key path and bridging changes to another key path

The usages look like

```swift
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
```

Note the comments. Only the bridging approach is safe from unintended strong capture.

The downside is that the bridge may require an additional receiving property so that
a key path can be used.
