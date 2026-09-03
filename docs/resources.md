# Resources and Influences

These resources influenced how I approached the project. They were used for concepts, community patterns, and performance thinking rather than as code to copy directly into the production report.

## Agile data modeling community

https://www.reddit.com/r/agiledatamodeling/

Useful themes:

- model data at the correct grain;
- make entity relationships explicit;
- separate domain/business meaning from tool-specific implementation;
- design models that can evolve rather than burying every rule in one monolithic report query.

## Power BI community

https://www.reddit.com/r/PowerBI/

Useful themes:

- practical Power Query/API pagination patterns;
- `Web.Contents` behavior;
- refresh troubleshooting;
- model/query organization;
- lessons from other developers dealing with API connectors and Power BI service limitations.

Community posts are experience-sharing, not authoritative documentation, so I cross-checked behavior against Microsoft documentation and direct benchmarks.

## One Billion Row Challenge (1BRC)

https://github.com/gunnarmorling/1brc

The challenge is about aggregating one billion rows as quickly as possible. The direct implementation details are Java-specific, but the project was useful as a performance-thinking reference.

Ideas adapted conceptually:

- reduce repeated passes;
- keep the hot working set small;
- avoid unnecessary object/row churn;
- reduce data as early as practical;
- make “latest per key” or aggregation work a single deliberate pass;
- measure wall-clock behavior rather than assuming an optimization helps.

The Trailer Tracking project did **not** attempt to reproduce memory-mapped Java or unsafe/SIMD techniques in Power Query. The value was the mindset: ask what work is actually necessary and where it should happen.

## Microsoft Power Query / Power BI documentation

### Power Query best practices

https://learn.microsoft.com/en-us/power-query/best-practices

Relevant guidance:

- filter early;
- do expensive operations later;
- document queries;
- use modular transformations;
- use appropriate data types.

### Why a Power Query query can run multiple times

https://learn.microsoft.com/en-us/power-query/multiple-queries

Relevant to understanding schema evaluation, privacy analysis, previews, and multiple source requests.

### Referencing Power Query queries

https://learn.microsoft.com/en-us/power-bi/guidance/power-query-referenced-queries

Relevant lesson: a referenced helper query is not automatically a shared persisted cache; referenced downstream queries can independently execute its source steps.

### Power Query Web connector

https://learn.microsoft.com/en-us/power-query/connectors/web/web

Used as the authoritative reference for web request headers such as `Accept-Encoding`.

### Table.Buffer

https://learn.microsoft.com/en-us/powerquery-m/table-buffer

Useful specifically because the documentation warns that buffering can make a query faster **or slower** and is not a universal performance fix.
