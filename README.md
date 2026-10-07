# Herald for Adjust

Sends [Herald](https://github.com/MkhytarMkhoian/herald-ios) events, revenue and ad revenue to
Adjust, over the [Adjust iOS SDK](https://github.com/adjust/ios_sdk).

## Install

In Xcode, File → Add Package Dependencies, and add both packages:

- `https://github.com/MkhytarMkhoian/herald-ios`, for `HeraldCore`;
- `https://github.com/MkhytarMkhoian/herald-ios-adjust`, for `HeraldAdjust`.

It works with Adjust 5, and needs iOS 15 or newer. All Herald for iOS
packages share one version, so use the same one for `herald-ios`.

## Set up

Build your `ADJConfig` as usual, but don't call `Adjust.initSdk` yourself: the service starts Adjust
silent, so nothing is sent before consent.

```swift
import AdjustSdk
import HeraldAdjust
import HeraldCore

// Adjust returns nil for a config it can't use, such as one without an app token.
guard let config = ADJConfig(appToken: "<app token>", environment: ADJEnvironmentProduction) else {
    fatalError("Adjust refused the config")
}

let tracker = AdjustAnalyticsTrackerService(
    eventTrackerFactory: TokenAdjustEventTrackerFactory(tokens: [
        "checkout_started": "abc123",  // tokens from the Adjust dashboard
        "sign_up": "def456",
    ]),
    propertySetterFactory: GenericAdjustPropertySetterFactory()
)
let service = AdjustAnalyticsService(config: config)

let provider = HeraldProvider(
    name: "adjust",
    events: tracker,
    properties: tracker,
    identity: service,
    lifecycle: service,
    consent: service
)
```

Adjust only knows events created in its dashboard, so events reach it through their tokens: an
event without a token isn't sent.

| Herald | Adjust |
| --- | --- |
| an event with a token | `trackEvent`, under its token, with its parameters as callback parameters (text) |
| an `AdjustRevenueEvent` | `trackEvent` under the purchase's token, with revenue, currency and deduplication id |
| an `AdjustAdRevenueEvent` | `trackAdRevenue`, which needs no token |
| a property | a global callback parameter (text) |
| `identify` / `reset` | the global callback parameter `user_id` / removing it |
| `start` | `disable()`, then `initSdk(config)`: Adjust starts silent |
| `setEnabled` | `enable()` / `disable()` |

An event token or ad revenue source that Adjust refuses, such as an empty one, is sent to Herald's
error reporter: Adjust itself would drop it with only a log line.

**Consent.** `start` turns Adjust off on every launch, so call `setEnabled` with the user's stored
answer after it. Adjust has no user id: `identify` uses the global callback parameter `user_id`, so
set one up in the dashboard, and don't give a property the same name. Pass `identityParameter:` to
`AdjustAnalyticsService` to use another name.

## Revenue

Your events don't conform to Adjust's types. A factory of your own builds one from your event, and
goes before the token factory:

```swift
import HeraldAdjust
import HeraldCore

struct PurchaseAdjustEventTrackerFactory: AdjustEventTrackerFactory {
    func create(_ event: any Event) -> Resolution<any AdjustEventTracker> {
        guard let purchase = event as? PurchaseCompleted else {
            return .declined
        }
        let revenue = AdjustRevenueEvent(
            name: purchase.name, revenue: purchase.price, currency: purchase.currency,
            deduplicationId: purchase.orderId)
        return .claimed([RevenueAdjustEventTracker(event: revenue, eventToken: "pur123")])
    }
}
```

## Documentation

The [Herald website](https://mkhytarmkhoian.github.io/herald-docs/) has the guides.

## License

Apache License 2.0. See [LICENSE](LICENSE).
