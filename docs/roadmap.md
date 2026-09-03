# Roadmap

## Completed in the Power BI phase

- reverse-engineered the existing tracking model;
- normalized multiple tracking sources;
- stabilized latest-record selection and duration semantics;
- reduced TMS history to a smaller serving shape;
- optimized API pagination and transfer behavior;
- documented report-facing fields/status concepts;
- redesigned the report shell and interaction pattern;
- established a public-safe documentation/code structure for portfolio use.

## Next architecture phase

### 1. External ingestion

Move tracking API requests to Python/Azure Functions or an equivalent scheduled ingestion service.

### 2. Incremental watermarking

Use the last successful source watermark with a small overlap instead of re-downloading the full rolling window during every report refresh.

### 3. Raw history

Persist raw source events with deterministic duplicate protection and source-run metadata.

### 4. Current-state table

Maintain one latest-known state per asset, independent of whether the asset emitted an event during the last report window.

### 5. Source health

Record last attempt, last success, row counts, errors, and freshness so a provider outage is distinguishable from “zero assets.”

### 6. Serving layer

Publish small report-shaped SQL objects for Power BI rather than requiring the PBIX to re-create ingestion/business logic.

### 7. Validation and testing

Add automated checks for:

- duplicate assets;
- stale tracking;
- key normalization;
- impossible/future timestamps;
- missing route mappings;
- business-rule regressions.

### 8. Deployment

Move from manually maintained report logic toward version-controlled deployment of SQL, ingestion code, and Power BI project artifacts in a private/approved environment.
