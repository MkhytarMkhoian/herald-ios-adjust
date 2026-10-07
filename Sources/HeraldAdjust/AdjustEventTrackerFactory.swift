import HeraldCore

/// Decides what Adjust gets for an event: `claimed` with the calls to make, `dropped` to send
/// nothing, or `declined` to let the next factory decide.
public protocol AdjustEventTrackerFactory: Sendable {
    func create(_ event: any Event) throws -> Resolution<any AdjustEventTracker>
}

/// Asks each factory in order and uses the first answer that isn't `declined`. If all decline,
/// nothing is sent. Stops the app if a ``FallbackFactory`` isn't last.
public struct CompositeAdjustEventTrackerFactory: AdjustEventTrackerFactory {
    private let factories: [any AdjustEventTrackerFactory]

    public init(_ factories: [any AdjustEventTrackerFactory]) {
        requireFallbackLast(factories)
        self.factories = factories
    }

    public func create(_ event: any Event) throws -> Resolution<any AdjustEventTracker> {
        try Resolution.firstOf(factories) { factory in try factory.create(event) }
    }
}
