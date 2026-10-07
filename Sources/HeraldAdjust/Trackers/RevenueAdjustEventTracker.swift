import HeraldCore

/// Sends a purchase under its dashboard token, with its revenue.
public struct RevenueAdjustEventTracker: AdjustEventTracker {
    private let event: AdjustRevenueEvent
    private let eventToken: String
    private let sdk: any AdjustSDK

    public init(event: AdjustRevenueEvent, eventToken: String) {
        self.init(event: event, eventToken: eventToken, sdk: LiveAdjustSDK())
    }

    init(event: AdjustRevenueEvent, eventToken: String, sdk: any AdjustSDK) {
        self.event = event
        self.eventToken = eventToken
        self.sdk = sdk
    }

    public func track() throws {
        sdk.trackEvent(try event.toAdjustEvent(token: eventToken))
    }
}
