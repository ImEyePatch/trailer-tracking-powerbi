# Power Query API Benchmark Notes

These timings came from development tests against a rolling telematics window. They are useful for showing the relative impact of changes, but they are not a controlled laboratory benchmark.

| Version | Observed refresh-preview time |
|---|---:|
| Original | ~9:00 |
| + binary/list buffering | 8:09 |
| + gzip | 4:50 |
| + one global reduction | 3:40 |
| Separate raw-pagination test | ~4:30 |

## Interpretation

The strongest measured improvement came from gzip compression. The one-global-reduction change also improved the observed full query.

The separate raw-pagination result was slower than the full optimized query, so the runs cannot be subtracted to estimate exact M transformation cost. The rolling API, Power Query evaluation, and network conditions introduced meaningful variance.

## Test hygiene learned during the project

- Query Diagnostics should be off during timing runs.
- Refresh one test query at a time.
- Disable load for benchmark-only queries.
- Do not infer performance from the first network request alone; include JSON parsing/evaluation.
- Use repeated runs/median values before making precise claims.
