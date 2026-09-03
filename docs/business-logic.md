# Business Logic — Sanitized

The public repository preserves the **shape** of the business problem without publishing production thresholds, route aliases, or commercial values.

## Core concepts

### Expected return

A route/schedule reference provides distance/drive-time context. The production report translated that into a planned return window and calculated an expected-return timestamp from the most recent relevant departure.

Public abstraction:

```text
expected_return = last_departure + configured_return_window(route)
variance_days   = current_date - expected_return_date
```

### Status families

**OK**

Asset is within its expected return window or is at an approved/excluded hub.

**Delayed**

Asset is beyond expected return and is not covered by an exclusion.

**Abandon**

Asset has been stopped/idle beyond a configured threshold while outside approved hubs.

**Not Tracking**

Tracking recency/motion-duration behavior indicates the provider may no longer be delivering trustworthy current-state data.

**Out of Network**

Tracking exists, but no relevant TMS order can be matched.

**Exclusion**

Catch-all for intentionally excluded operational states.

## Values intentionally omitted

The public repo does not include:

- exact idle thresholds;
- exact “not tracking” thresholds;
- customer-specific location aliases;
- customer/contract route rules;
- return-day lookup values;
- fee amounts or commercial calculations;
- production customer/carrier identifiers.
