import HeraldCore

/// Claims every event whose name has a dashboard token in `tokens`, and declines the rest.
///
/// Adjust only knows events created in its dashboard, so there is no generic event factory: an
/// event without a token isn't sent. One token per event; for an event that should count as
/// several Adjust events, write a factory that answers with several ``TokenAdjustEventTracker``s
/// and put it before this one.
public struct TokenAdjustEventTrackerFactory: AdjustEventTrackerFactory {
    private let tokens: [String: String]
    private let sdk: any AdjustSDK

    public init(tokens: [String: String]) {
        self.init(tokens: tokens, sdk: LiveAdjustSDK())
    }

    init(tokens: [String: String], sdk: any AdjustSDK) {
        self.tokens = tokens
        self.sdk = sdk
    }

    public func create(_ event: any Event) -> Resolution<any AdjustEventTracker> {
        guard let token = tokens[event.name] else {
            return .declined
        }
        return .claimed([TokenAdjustEventTracker(event: event, eventToken: token, sdk: sdk)])
    }
}

/// Adds any property as a global callback parameter. Adjust has no user profile, so this covers
/// ``UserProperty`` too. Claims every property, so it goes last in a chain.
public struct GenericAdjustPropertySetterFactory: AdjustPropertySetterFactory, FallbackFactory {
    private let sdk: any AdjustSDK

    public init() {
        self.init(sdk: LiveAdjustSDK())
    }

    init(sdk: any AdjustSDK) {
        self.sdk = sdk
    }

    public func create(_ property: any Property) -> Resolution<any AdjustPropertySetter> {
        .claimed([GenericAdjustPropertySetter(property: property, sdk: sdk)])
    }
}
