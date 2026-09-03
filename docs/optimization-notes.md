# Optimization Notes

## 1. Historical lookup anti-pattern

### Before

```text
tracking row
  -> nested join to all historical rows for asset
  -> filter history by event/departure rule
  -> sort candidate history
  -> take first/latest row
```

That pattern is understandable in Power Query, but it becomes expensive as the history source grows.

### After

```text
SQL source
  -> normalize asset key
  -> reduce stop/order history
  -> rank rows per asset
  -> return latest relevant row only
  -> Power BI joins small serving result
```

This moves set-based work to the database and reduces transfer volume.

## 2. Reduce wide sources early

Only fields that contributed to joins, calculations, tooltips, or visuals were kept. Debug/helper columns that were useful during development were removed from the production-facing contract.

## 3. API pagination

The Provider A API used a cursor (`endAt`-style behavior), so the next request depended on the previous response. Pagination therefore remained sequential.

Trying to parallelize that dependency chain would add complexity without matching the API contract.

## 4. Compression

Requesting:

```http
Accept-Encoding: gzip
```

produced the largest measured improvement in the Power Query API path.

## 5. Buffering — narrow use only

`Binary.Buffer` was used around a single web response so that the same response bytes were stable inside that query evaluation.

`List.Buffer` was used around the generated page list so downstream consumers did not repeatedly enumerate a lazy list inside the same evaluation.

This is deliberately different from assuming `Table.Buffer` creates a global cache. It does not.

## 6. One global reduction

### Before

```text
page 1 -> table -> clean -> group -> max
page 2 -> table -> clean -> group -> max
...
combine page results -> group -> max again
```

### After

```text
page 1 raw rows
page 2 raw rows
...
combine raw lists
-> Table.FromRecords once
-> clean/convert once
-> group/max once
```

At the observed scale (~tens of thousands of events in the rolling window), holding the raw page lists was a better tradeoff than repeated group/reduction work.

## 7. Evaluation behavior

Power Query can evaluate referenced sources multiple times. A helper query should not be treated as a persisted materialization layer.

Practical lessons:

- disable load for pure staging helpers;
- avoid relying on preview behavior as proof of model-refresh behavior;
- test with background preview/diagnostics controlled;
- measure the specific query being changed;
- externalize expensive/reused ingestion when persistence is required.

## 8. Benchmark discipline

One raw-HTTP test was slower than the full transformed query. That did **not** mean transformations had negative cost; it showed network/API/evaluation variability was large enough that single-run subtraction was invalid.

The performance numbers in this repo are therefore recorded as observed development timings, not scientific claims.
