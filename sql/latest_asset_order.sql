/*
    Public portfolio example.
    All names are synthetic. Production customer filters, codes, schemas,
    and identifiers have intentionally been removed.

    Goal:
      Return one latest relevant TMS order per asset BEFORE Power BI reads it.
*/

WITH BaseOrders AS
(
    SELECT
        o.order_id,
        UPPER(REPLACE(LTRIM(RTRIM(o.asset_id)), ' ', '')) AS asset_id,
        o.trip_id,
        o.customer_id
    FROM warehouse.orders AS o
    WHERE o.asset_id IS NOT NULL
),
LatestStop AS
(
    SELECT
        b.order_id,
        b.asset_id,
        b.trip_id,
        b.customer_id,
        s.actual_departure,
        s.actual_arrival,
        ROW_NUMBER() OVER
        (
            PARTITION BY b.asset_id
            ORDER BY
                s.actual_departure DESC,
                s.actual_arrival DESC,
                b.order_id DESC
        ) AS asset_rank
    FROM BaseOrders AS b
    OUTER APPLY
    (
        SELECT TOP (1)
            st.actual_departure,
            st.actual_arrival
        FROM warehouse.stops AS st
        WHERE st.order_id = b.order_id
        ORDER BY
            st.actual_departure DESC,
            st.actual_arrival DESC
    ) AS s
)
SELECT
    asset_id       AS Asset_ID,
    order_id       AS Order_ID,
    trip_id        AS Trip_ID,
    customer_id    AS Customer_ID,
    actual_departure,
    actual_arrival
FROM LatestStop
WHERE asset_rank = 1;
