import AdjustSdk
import Foundation
import HeraldCore

@testable import HeraldAdjust

struct TestEvent: Event {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
}

struct TestProperty: Property {
    let name: String
    let value: AnalyticsValue
}

/// Records the Adjust calls instead of making them, each as one line. Adjust's events are read
/// back through key-value coding, because Adjust leaves fields that were never set empty although
/// its headers say they're always there. Locked, so any thread can call it: hence
/// `@unchecked Sendable`.
final class RecordingAdjustSDK: AdjustSDK, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var calls: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func initSdk() { record("initSdk") }

    func trackEvent(_ event: ADJEvent) {
        var line = "trackEvent \(text(event, "eventToken"))"
        line += " revenue=\(text(event, "revenue")) currency=\(text(event, "currency"))"
        line += " deduplicationId=\(text(event, "deduplicationId"))"
        line += formattedValues(event.value(forKey: "callbackParameters"))
        record(line)
    }

    func trackAdRevenue(_ adRevenue: ADJAdRevenue) {
        var line = "trackAdRevenue \(text(adRevenue, "source"))"
        line += " revenue=\(text(adRevenue, "revenue")) currency=\(text(adRevenue, "currency"))"
        line += " impressions=\(text(adRevenue, "adImpressionsCount"))"
        line += " network=\(text(adRevenue, "adRevenueNetwork"))"
        line += " unit=\(text(adRevenue, "adRevenueUnit"))"
        line += " placement=\(text(adRevenue, "adRevenuePlacement"))"
        line += formattedValues(adRevenue.value(forKey: "callbackParameters"))
        record(line)
    }

    func enable() { record("enable") }

    func disable() { record("disable") }

    func addGlobalCallbackParameter(_ value: String, forKey key: String) {
        record("addGlobalCallbackParameter \(key)=\(value)")
    }

    func removeGlobalCallbackParameter(forKey key: String) {
        record("removeGlobalCallbackParameter \(key)")
    }

    /// The field `key` of `object`, or `nil` when it was never set.
    private func text(_ object: NSObject, _ key: String) -> String {
        if let value = object.value(forKey: key) {
            return "\(value)"
        }
        return "nil"
    }

    /// Callback parameters, sorted by key, each with its type, like ` seats=String(3)`.
    private func formattedValues(_ parameters: Any?) -> String {
        guard let parameters = parameters as? [String: Any] else {
            return ""
        }
        var text = ""
        for key in parameters.keys.sorted() {
            let value = parameters[key]!
            text += " \(key)=\(type(of: value))(\(value))"
        }
        return text
    }

    private func record(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(line)
    }
}

/// What Herald sent to its error reporter. Locked like ``RecordingAdjustSDK``.
final class ReportedFailures: @unchecked Sendable {
    private let lock = NSLock()
    private var failures: [AnalyticsFailure] = []

    var all: [AnalyticsFailure] {
        lock.lock()
        defer { lock.unlock() }
        return failures
    }

    func append(_ failure: AnalyticsFailure) {
        lock.lock()
        defer { lock.unlock() }
        failures.append(failure)
    }
}
