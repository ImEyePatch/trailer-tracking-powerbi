# Project History

## Stage 1 — Report discovery and documentation

The project started with an existing Power BI trailer-tracking report whose logic had grown organically. The first task was to understand what each query, field, button, KPI, and status actually represented before changing the model.

Work included:

- mapping the data flow from multiple tracking sources into the consolidated tracking table;
- documenting report-facing fields and status definitions;
- identifying the role of the TMS order/stop source and the route/schedule reference source;
- confirming refresh behavior and report dependencies;
- planning user-facing tooltips/descriptions so operators would not need tribal knowledge to interpret statuses.

## Stage 2 — Establish a common tracking contract

The two telematics sources exposed different shapes and semantics. They were normalized into a common report contract containing the current asset, location, landmark, motion state, duration values, event timestamp, and source marker.

A key lesson was that “same column name” does not guarantee “same meaning.” Duration and idle fields had to be reviewed source by source rather than coerced generically.

## Stage 3 — Enrichment with TMS and schedule data

The consolidated tracking state was enriched with:

- latest/relevant order information from the TMS warehouse;
- trip/route identifiers;
- carrier/payee context where available;
- route mileage and planned return-window information;
- expected-return and variance calculations.

This stage turned location telemetry into an operational view instead of a GPS-only view.

## Stage 4 — Correctness hardening

Several model behaviors were tightened:

- normalized asset keys before joins;
- deterministic latest-event selection per asset;
- explicit handling of source-specific null duration fields;
- reconstruction of duration values when type coercion broke a report field;
- removal/rebinding of stale visual field references after lineage-changing transformations;
- separation of “latest overall TMS state” from “historical as-of event” semantics so the business owner could choose intentionally rather than inherit accidental behavior.

## Stage 5 — SQL/Power Query performance investigation

The largest structural bottleneck was the historical TMS lookup design. The SQL query returned stop-level history, and Power Query performed repeated per-asset nested filtering/sorting to choose a row relevant to each tracking event.

As history grew, that increased:

- database reads;
- transferred data volume;
- local scans and sorts;
- query-evaluation pressure;
- refresh fragility.

The redesign pushed “latest relevant row per asset” to SQL and reduced the output width before Power BI received it.

## Stage 6 — API performance investigation

The Provider A API required sequential cursor-based pagination. A Python implementation could retrieve the same logical window much faster than the original Power Query path, so the API work was benchmarked separately from the SQL work.

The investigation isolated several useful changes:

- gzip response compression;
- binary buffering for each page within a single evaluation;
- list buffering for generated page results within a single evaluation;
- collect raw page rows first, then transform once;
- one global latest-per-asset reduction instead of one per page plus another after combination.

The final observed development run dropped from about nine minutes to 3:40.

## Stage 7 — Power BI evaluation behavior

Testing also exposed an important Power Query behavior: referenced queries are not guaranteed to behave like a shared materialized cache. Desktop refresh, schema evaluation, privacy evaluation, previews, and dependent queries can create additional source evaluations.

That led to practical model rules:

- staging/helper queries should not be loaded unless the model actually needs them;
- do not assume `Table.Buffer` creates a cross-query cache;
- benchmark only one controlled query at a time when isolating performance;
- keep Query Diagnostics off during timing runs because diagnostic activity itself can materially change evaluation behavior.

## Stage 8 — Dashboard redesign and usability

The visual layer was treated as part of the engineering work, not an afterthought. The redesign work used a 1280×720 page, KPI cards, left-side slicers, a large operational table/matrix, SVG/icon assets, and clear interaction states.

A priority requirement was user-facing descriptions/tooltips for buttons, statuses, and fields so the dashboard could be maintained and used without relying on undocumented tribal knowledge.

## Stage 9 — Long-term architecture

The Power BI version proved the operational logic and produced a usable report, but the long-term goal is to move source ingestion and persistence outside the PBIX.

The target platform separates:

1. source ingestion,
2. raw/landing history,
3. source health,
4. normalization,
5. validation/business rules,
6. exceptions/overrides,
7. serving/reporting,
8. Power BI.

This preserves last-good data when a provider is unavailable and lets Power BI query a small, stable serving layer rather than repeatedly behaving like an ETL engine.
