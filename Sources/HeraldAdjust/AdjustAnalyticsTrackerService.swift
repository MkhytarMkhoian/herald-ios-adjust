import HeraldCore

/// Sends events and properties to Adjust, as its factory chains decide. The calls for one event
/// run in order, and if one fails the rest don't run. Anything no factory claims isn't sent.
///
/// ```swift
/// let tracker = AdjustAnalyticsTrackerService(
///     eventTrackerFactory: TokenAdjustEventTrackerFactory(tokens: [
///         "checkout_started": "abc123",  // tokens from the Adjust dashboard
///         "sign_up": "def456",
///     ]),
///     propertySetterFactory: GenericAdjustPropertySetterFactory()
/// )
/// ```
public struct AdjustAnalyticsTrackerService: EventTrackerService, PropertyTrackerService {
    private let eventTrackerFactory: any AdjustEventTrackerFactory
    private let propertySetterFactory: any AdjustPropertySetterFactory

    public init(
        eventTrackerFactory: any AdjustEventTrackerFactory,
        propertySetterFactory: any AdjustPropertySetterFactory
    ) {
        self.eventTrackerFactory = eventTrackerFactory
        self.propertySetterFactory = propertySetterFactory
    }

    public func track(_ event: any Event) {
        do {
            for tracker in try eventTrackerFactory.create(event).handlers() {
                try tracker.track()
            }
        } catch {
            Herald.reportFailure(error)
        }
    }

    public func set(_ property: any Property) {
        do {
            for setter in try propertySetterFactory.create(property).handlers() {
                try setter.set()
            }
        } catch {
            Herald.reportFailure(error)
        }
    }
}
