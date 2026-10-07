import AdjustSdk
import HeraldCore

/// A purchase, in the fields Adjust's revenue tracking takes.
///
/// Your events don't conform to it: your Adjust factory builds one from your event and sends it
/// with ``RevenueAdjustEventTracker``, under the purchase's dashboard token.
public struct AdjustRevenueEvent: Event, Equatable {
    /// Not sent. Only used in failure reports.
    public let name: String
    public let revenue: Double
    public let currency: String

    /// Makes a purchase sent twice count once.
    public let deduplicationId: String?
    public let parameters: [String: AnalyticsValue]

    public init(
        name: String,
        revenue: Double,
        currency: String,
        deduplicationId: String? = nil,
        parameters: [String: AnalyticsValue] = [:]
    ) {
        self.name = name
        self.revenue = revenue
        self.currency = currency
        self.deduplicationId = deduplicationId
        self.parameters = parameters
    }

    func toAdjustEvent(token eventToken: String) throws -> ADJEvent {
        let event = try adjustEvent(token: eventToken, eventName: name, parameters: parameters)
        event.setRevenue(revenue, currency: currency)
        if let deduplicationId {
            event.setDeduplicationId(deduplicationId)
        }
        return event
    }
}

/// Ad revenue, in the fields Adjust's ad revenue tracking takes. Built by your Adjust factory and
/// sent with ``AdRevenueAdjustEventTracker``.
public struct AdjustAdRevenueEvent: Event, Equatable {
    /// Not sent. Only used in failure reports.
    public let name: String

    /// Such as `applovin_max_sdk` or `admob_sdk`.
    public let source: String
    public let revenue: Double
    public let currency: String
    public let adImpressionsCount: Int?
    public let adRevenueNetwork: String?
    public let adRevenueUnit: String?
    public let adRevenuePlacement: String?

    /// Sent as callback parameters, as text.
    public let parameters: [String: AnalyticsValue]

    public init(
        name: String,
        source: String,
        revenue: Double,
        currency: String,
        adImpressionsCount: Int? = nil,
        adRevenueNetwork: String? = nil,
        adRevenueUnit: String? = nil,
        adRevenuePlacement: String? = nil,
        parameters: [String: AnalyticsValue] = [:]
    ) {
        self.name = name
        self.source = source
        self.revenue = revenue
        self.currency = currency
        self.adImpressionsCount = adImpressionsCount
        self.adRevenueNetwork = adRevenueNetwork
        self.adRevenueUnit = adRevenueUnit
        self.adRevenuePlacement = adRevenuePlacement
        self.parameters = parameters
    }

    /// Throws if Adjust doesn't accept the source, such as an empty one: Adjust would drop the ad
    /// revenue with only a log line.
    func toAdjustAdRevenue() throws -> ADJAdRevenue {
        guard let adRevenue = ADJAdRevenue(source: source), adRevenue.isValid() else {
            throw AdjustRefusal(
                description: "Ad revenue '\(name)' has a source Adjust refuses: '\(source)'.")
        }
        adRevenue.setRevenue(revenue, currency: currency)
        if let adImpressionsCount {
            adRevenue.setAdImpressionsCount(Int32(adImpressionsCount))
        }
        if let adRevenueNetwork {
            adRevenue.setAdRevenueNetwork(adRevenueNetwork)
        }
        if let adRevenueUnit {
            adRevenue.setAdRevenueUnit(adRevenueUnit)
        }
        if let adRevenuePlacement {
            adRevenue.setAdRevenuePlacement(adRevenuePlacement)
        }
        for (key, value) in parameters {
            adRevenue.addCallbackParameter(key, value: value.asString)
        }
        return adRevenue
    }
}
