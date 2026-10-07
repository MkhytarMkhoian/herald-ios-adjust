import HeraldCore

/// Adds `property` as a global callback parameter, as text, so Adjust attaches it to every later
/// event.
///
/// ``AdjustAnalyticsService`` keeps the user id in the same place, so a property named like its
/// identity parameter replaces the user id.
public struct GenericAdjustPropertySetter: AdjustPropertySetter {
    private let property: any Property
    private let sdk: any AdjustSDK

    public init(property: any Property) {
        self.init(property: property, sdk: LiveAdjustSDK())
    }

    init(property: any Property, sdk: any AdjustSDK) {
        self.property = property
        self.sdk = sdk
    }

    public func set() {
        sdk.addGlobalCallbackParameter(property.value.asString, forKey: property.name)
    }
}
