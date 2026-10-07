import HeraldCore

/// Sends `event` under `eventToken`. Its name isn't sent: the token identifies the event.
public struct TokenAdjustEventTracker: AdjustEventTracker {
    private let event: any Event
    private let eventToken: String
    private let sdk: any AdjustSDK

    public init(event: any Event, eventToken: String) {
        self.init(event: event, eventToken: eventToken, sdk: LiveAdjustSDK())
    }

    init(event: any Event, eventToken: String, sdk: any AdjustSDK) {
        self.event = event
        self.eventToken = eventToken
        self.sdk = sdk
    }

    public func track() throws {
        sdk.trackEvent(
            try adjustEvent(token: eventToken, eventName: event.name, parameters: event.parameters))
    }
}
