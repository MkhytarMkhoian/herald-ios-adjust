import AdjustSdk
import HeraldCore

/// An `ADJEvent` for the dashboard event `eventToken`, with `parameters` as callback parameters.
/// Adjust's parameters are text, so values are sent as text.
///
/// Throws if Adjust doesn't accept the token, such as an empty one: Adjust would drop the event
/// with only a log line.
func adjustEvent(
    token eventToken: String, eventName: String, parameters: [String: AnalyticsValue]
) throws -> ADJEvent {
    guard let event = ADJEvent(eventToken: eventToken), event.isValid() else {
        throw AdjustRefusal(
            description: "Event '\(eventName)' has an event token Adjust refuses: "
                + "'\(eventToken)'. Use the token from the Adjust dashboard.")
    }
    for (key, value) in parameters {
        event.addCallbackParameter(key, value: value.asString)
    }
    return event
}

/// Why this module refused an event: it says what to change.
struct AdjustRefusal: Error, CustomStringConvertible {
    let description: String
}
