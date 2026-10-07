import HeraldCore
import Testing

@testable import HeraldAdjust

@Suite struct Conversion {
    let adjust = RecordingAdjustSDK()

    @Test func anEventBecomesTheTokenWithEveryParameterAsText() throws {
        let event = TestEvent(
            name: "checkout_started",
            parameters: [
                "plan": .string("pro"), "seats": .int(3), "price": .double(9.99),
                "trial": .bool(false),
            ])

        try TokenAdjustEventTracker(event: event, eventToken: "abc123", sdk: adjust).track()

        let call = try #require(adjust.calls.first)
        #expect(call.hasPrefix("trackEvent abc123 revenue=nil currency=nil deduplicationId=nil"))
        #expect(call.contains("plan=") && call.contains("(pro)"))
        #expect(call.contains("price=") && call.contains("(9.99)"))
        #expect(call.contains("seats=") && call.contains("(3)"))
        #expect(call.contains("trial=") && call.contains("(false)"))
        #expect(!call.contains("Int(") && !call.contains("Double(") && !call.contains("Bool("))
    }

    @Test func aRevenueEventCarriesItsRevenueAndDeduplicationId() throws {
        let purchase = AdjustRevenueEvent(
            name: "purchase", revenue: 4.99, currency: "EUR", deduplicationId: "order-1")

        try RevenueAdjustEventTracker(event: purchase, eventToken: "pur123", sdk: adjust).track()

        #expect(
            adjust.calls == [
                "trackEvent pur123 revenue=4.99 currency=EUR deduplicationId=order-1"
            ])
    }

    @Test func adRevenueSetsOnlyTheFieldsThatArePresent() throws {
        let adRevenue = AdjustAdRevenueEvent(
            name: "ad_shown", source: "applovin_max_sdk", revenue: 0.01, currency: "USD",
            adRevenueNetwork: "admob")

        try AdRevenueAdjustEventTracker(event: adRevenue, sdk: adjust).track()

        let call = try #require(adjust.calls.first)
        #expect(call.hasPrefix("trackAdRevenue applovin_max_sdk revenue=0.01 currency=USD"))
        #expect(call.contains("network=admob unit=nil placement=nil"))
    }

    @Test func anEmptyTokenIsRefusedSinceAdjustWouldDropTheEventSilently() {
        #expect {
            try TokenAdjustEventTracker(
                event: TestEvent(name: "checkout_started"), eventToken: "", sdk: adjust
            ).track()
        } throws: { error in
            "\(error)".contains("event token Adjust refuses")
        }
        #expect(adjust.calls.isEmpty)
    }

    @Test func revenueEventsAreEqualByValue() {
        #expect(
            AdjustRevenueEvent(name: "p", revenue: 1, currency: "EUR")
                == AdjustRevenueEvent(name: "p", revenue: 1, currency: "EUR"))
        #expect(
            AdjustRevenueEvent(name: "p", revenue: 1, currency: "EUR")
                != AdjustRevenueEvent(name: "p", revenue: 1, currency: "USD"))
        #expect(
            AdjustAdRevenueEvent(name: "a", source: "s", revenue: 1, currency: "USD")
                != AdjustAdRevenueEvent(
                    name: "a", source: "s", revenue: 1, currency: "USD", adImpressionsCount: 2))
    }
}

/// A purchase, as an app describes it.
private struct PurchaseCompleted: Event {
    let price: Double
    var name: String { "purchase_completed" }
}

/// Sends `PurchaseCompleted` as revenue under its own token, and declines everything else.
private struct PurchaseAdjustEventTrackerFactory: AdjustEventTrackerFactory {
    let sdk: any AdjustSDK

    func create(_ event: any Event) -> Resolution<any AdjustEventTracker> {
        guard let purchase = event as? PurchaseCompleted else {
            return .declined
        }
        let revenue = AdjustRevenueEvent(
            name: purchase.name, revenue: purchase.price, currency: "EUR")
        return .claimed([RevenueAdjustEventTracker(event: revenue, eventToken: "pur123", sdk: sdk)])
    }
}

@Suite struct Factories {
    let adjust = RecordingAdjustSDK()

    @Test func theTokenFactoryClaimsMappedEventsAndDeclinesTheRest() throws {
        let tracker = AdjustAnalyticsTrackerService(
            eventTrackerFactory: TokenAdjustEventTrackerFactory(
                tokens: ["sign_up": "abc123"], sdk: adjust),
            propertySetterFactory: GenericAdjustPropertySetterFactory(sdk: adjust)
        )
        let herald = Herald(providers: [HeraldProvider(name: "adjust", events: tracker)])

        herald.track(TestEvent(name: "sign_up"))
        herald.track(TestEvent(name: "cart_viewed"))

        #expect(adjust.calls.count == 1)
        #expect(adjust.calls.first?.hasPrefix("trackEvent abc123") == true)
    }

    @Test func aCustomFactoryBeforeTheTokenFactorySendsPurchases() {
        let tracker = AdjustAnalyticsTrackerService(
            eventTrackerFactory: CompositeAdjustEventTrackerFactory([
                PurchaseAdjustEventTrackerFactory(sdk: adjust),
                TokenAdjustEventTrackerFactory(tokens: ["sign_up": "abc123"], sdk: adjust),
            ]),
            propertySetterFactory: GenericAdjustPropertySetterFactory(sdk: adjust)
        )
        let herald = Herald(providers: [HeraldProvider(name: "adjust", events: tracker)])

        herald.track(PurchaseCompleted(price: 4.99))
        herald.track(TestEvent(name: "sign_up"))

        #expect(
            adjust.calls == [
                "trackEvent pur123 revenue=4.99 currency=EUR deduplicationId=nil",
                "trackEvent abc123 revenue=nil currency=nil deduplicationId=nil",
            ])
    }

    @Test func aChainEndingInRequireMappedReportsAnUnclaimedEventThroughHerald() throws {
        let failures = ReportedFailures()
        let tracker = AdjustAnalyticsTrackerService(
            eventTrackerFactory: CompositeAdjustEventTrackerFactory([
                TokenAdjustEventTrackerFactory(tokens: [:], sdk: adjust),
                RequireMappedAdjustEventTrackerFactory(),
            ]),
            propertySetterFactory: RequireMappedAdjustPropertySetterFactory()
        )
        let herald = Herald(
            providers: [HeraldProvider(name: "adjust", events: tracker, properties: tracker)],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(TestEvent(name: "checkout_started"))
        herald.set(TestProperty(name: "plan", value: .string("pro")))

        #expect(adjust.calls.isEmpty)
        let failure = try #require(failures.all.first)
        #expect(failure.operation == .track(eventName: "checkout_started"))
        #expect(failure.error is UnhandledEventError)
        #expect(failures.all.last?.error is UnhandledPropertyError)
    }

    @Test func aPropertyIsAGlobalCallbackParameterAsText() {
        GenericAdjustPropertySetter(
            property: TestProperty(name: "seats", value: .int(3)), sdk: adjust
        )
        .set()

        #expect(adjust.calls == ["addGlobalCallbackParameter seats=3"])
    }
}

@Suite struct Service {
    let adjust = RecordingAdjustSDK()

    @Test func startTurnsAdjustOffBeforeStartingItSoItStartsSilent() {
        AdjustAnalyticsService(sdk: adjust).start()

        #expect(adjust.calls == ["disable", "initSdk"])
    }

    @Test func consentTurnsAdjustOnAndOff() {
        let service = AdjustAnalyticsService(sdk: adjust)

        service.setEnabled(true)
        service.setEnabled(false)

        #expect(adjust.calls == ["enable", "disable"])
    }

    @Test func identityIsAGlobalCallbackParameter() {
        let service = AdjustAnalyticsService(sdk: adjust)

        service.identify(Identity(userId: "user-1"))
        service.reset()

        #expect(
            adjust.calls == [
                "addGlobalCallbackParameter user_id=user-1",
                "removeGlobalCallbackParameter user_id",
            ])
    }

    @Test func theIdentityParameterCanBeRenamed() {
        let service = AdjustAnalyticsService(identityParameter: "customer", sdk: adjust)

        service.identify(Identity(userId: "user-1"))

        #expect(adjust.calls == ["addGlobalCallbackParameter customer=user-1"])
    }
}
