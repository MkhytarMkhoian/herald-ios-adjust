import AdjustSdk

/// The Adjust calls this module makes, so the tests can record them instead: ``LiveAdjustSDK`` in
/// the app, a recorder in the tests. Adjust's API is static functions on `Adjust`, which a test
/// can't replace.
protocol AdjustSDK: Sendable {
    func initSdk()
    func trackEvent(_ event: ADJEvent)
    func trackAdRevenue(_ adRevenue: ADJAdRevenue)
    func enable()
    func disable()
    func addGlobalCallbackParameter(_ value: String, forKey key: String)
    func removeGlobalCallbackParameter(forKey key: String)
}

/// Calls Adjust itself.
///
/// Only the service starts Adjust, so only its copy holds the app's `ADJConfig`. The config isn't
/// marked `Sendable`, but it's only read, once, when Adjust starts: hence `@unchecked Sendable`.
struct LiveAdjustSDK: AdjustSDK, @unchecked Sendable {
    var config: ADJConfig?

    func initSdk() {
        Adjust.initSdk(config)
    }

    func trackEvent(_ event: ADJEvent) {
        Adjust.trackEvent(event)
    }

    func trackAdRevenue(_ adRevenue: ADJAdRevenue) {
        Adjust.trackAdRevenue(adRevenue)
    }

    func enable() {
        Adjust.enable()
    }

    func disable() {
        Adjust.disable()
    }

    func addGlobalCallbackParameter(_ value: String, forKey key: String) {
        Adjust.addGlobalCallbackParameter(value, forKey: key)
    }

    func removeGlobalCallbackParameter(forKey key: String) {
        Adjust.removeGlobalCallbackParameter(forKey: key)
    }
}
