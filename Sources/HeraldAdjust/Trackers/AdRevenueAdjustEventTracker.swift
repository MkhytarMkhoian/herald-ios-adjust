import HeraldCore

/// Sends ad revenue. Unlike events, it needs no dashboard token.
public struct AdRevenueAdjustEventTracker: AdjustEventTracker {
    private let event: AdjustAdRevenueEvent
    private let sdk: any AdjustSDK

    public init(event: AdjustAdRevenueEvent) {
        self.init(event: event, sdk: LiveAdjustSDK())
    }

    init(event: AdjustAdRevenueEvent, sdk: any AdjustSDK) {
        self.event = event
        self.sdk = sdk
    }

    public func track() throws {
        sdk.trackAdRevenue(try event.toAdjustAdRevenue())
    }
}
