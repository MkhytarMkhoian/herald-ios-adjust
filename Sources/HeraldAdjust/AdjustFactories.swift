import HeraldCore

/// The Adjust dashboard token for events of one type, or of a subclass of it:
/// `AdjustToken(SignUpCompleted.self, "abc123")`.
public struct AdjustToken: Sendable {
    let token: String
    let eventTypeName: String
    let eventTypeID: ObjectIdentifier
    private let isMatch: @Sendable (any Event) -> Bool

    public init<E: Event>(_ eventType: E.Type, _ token: String) {
        self.token = token
        eventTypeName = String(describing: eventType)
        eventTypeID = ObjectIdentifier(eventType)
        isMatch = { $0 is E }
    }

    func matches(_ event: any Event) -> Bool {
        isMatch(event)
    }
}

/// Sends each event that has a token in `tokens` under that token, and declines the rest:
///
/// ```swift
/// TokenAdjustEventTrackerFactory(tokens: [AdjustToken(SignUpCompleted.self, "abc123")])
/// ```
///
/// Events are matched by type, not by name, so a renamed event keeps its token. A type listed
/// twice stops the app at start-up.
///
/// One token per event; for an event that should count as several Adjust events, write a factory
/// that answers with several ``TokenAdjustEventTracker``s and put it before this one.
public struct TokenAdjustEventTrackerFactory: AdjustEventTrackerFactory {
    private let tokens: [AdjustToken]
    private let sdk: any AdjustSDK

    public init(tokens: [AdjustToken]) {
        self.init(tokens: tokens, sdk: LiveAdjustSDK())
    }

    init(tokens: [AdjustToken], sdk: any AdjustSDK) {
        if let repeated = repeatedEventType(in: tokens) {
            preconditionFailure("\(repeated) has two Adjust tokens. Give each event one token.")
        }
        self.tokens = tokens
        self.sdk = sdk
    }

    public func create(_ event: any Event) -> Resolution<any AdjustEventTracker> {
        guard let match = tokens.first(where: { $0.matches(event) }) else {
            return .declined
        }
        return .claimed([TokenAdjustEventTracker(event: event, eventToken: match.token, sdk: sdk)])
    }
}

/// The name of the first event type listed twice, if any.
func repeatedEventType(in tokens: [AdjustToken]) -> String? {
    var seen: Set<ObjectIdentifier> = []
    return tokens.first { !seen.insert($0.eventTypeID).inserted }?.eventTypeName
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
