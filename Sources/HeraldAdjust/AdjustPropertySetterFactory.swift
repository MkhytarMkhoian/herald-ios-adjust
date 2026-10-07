import HeraldCore

public protocol AdjustPropertySetterFactory: Sendable {
    func create(_ property: any Property) throws -> Resolution<any AdjustPropertySetter>
}

/// Asks each factory in order and uses the first answer that isn't `declined`. If all decline,
/// nothing is sent. Stops the app if a ``FallbackFactory`` isn't last.
public struct CompositeAdjustPropertySetterFactory: AdjustPropertySetterFactory {
    private let factories: [any AdjustPropertySetterFactory]

    public init(_ factories: [any AdjustPropertySetterFactory]) {
        requireFallbackLast(factories)
        self.factories = factories
    }

    public func create(_ property: any Property) throws -> Resolution<any AdjustPropertySetter> {
        try Resolution.firstOf(factories) { factory in try factory.create(property) }
    }
}
