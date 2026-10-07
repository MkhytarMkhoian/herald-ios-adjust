import HeraldCore

/// Fails for any event that reaches it, so the error reporter shows events nobody mapped. Put it
/// last in a chain.
public struct RequireMappedAdjustEventTrackerFactory: AdjustEventTrackerFactory, FallbackFactory {
    public init() {}

    public func create(_ event: any Event) throws -> Resolution<any AdjustEventTracker> {
        throw UnhandledEventError(event: event)
    }
}

public struct RequireMappedAdjustPropertySetterFactory: AdjustPropertySetterFactory,
    FallbackFactory
{
    public init() {}

    public func create(_ property: any Property) throws -> Resolution<any AdjustPropertySetter> {
        throw UnhandledPropertyError(property: property)
    }
}
