import AdjustSdk
import HeraldCore

/// Adjust's lifecycle, identity and consent.
///
/// `start` turns Adjust off and only then starts it with `config`, so nothing is sent, not even the
/// install, until `setEnabled(true)` turns it on. Turning it off after the start would be too late:
/// the first session would already be on its way. So let this service start Adjust; don't call
/// `Adjust.initSdk` yourself.
///
/// `start` turns Adjust off on every launch, so call `setEnabled` with the stored answer after it.
///
/// Adjust has no user id, so `identify` adds it as the global callback parameter
/// `identityParameter`. Set up a parameter with that name in the Adjust dashboard, and don't give a
/// property the same name.
public struct AdjustAnalyticsService: AnalyticsLifecycleService, IdentifiableUserService,
    ConsentService
{
    private let identityParameter: String
    private let sdk: any AdjustSDK

    public init(config: ADJConfig, identityParameter: String = "user_id") {
        self.init(identityParameter: identityParameter, sdk: LiveAdjustSDK(config: config))
    }

    init(identityParameter: String = "user_id", sdk: any AdjustSDK) {
        self.identityParameter = identityParameter
        self.sdk = sdk
    }

    public func start() {
        sdk.disable()
        sdk.initSdk()
    }

    /// Adjust has no flush call.
    public func flush() {}

    public func setEnabled(_ enabled: Bool) {
        if enabled {
            sdk.enable()
        } else {
            sdk.disable()
        }
    }

    public func identify(_ identity: Identity) {
        sdk.addGlobalCallbackParameter(identity.userId, forKey: identityParameter)
    }

    public func reset() {
        sdk.removeGlobalCallbackParameter(forKey: identityParameter)
    }
}
