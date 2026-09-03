let
    // Public structural example only.
    // Production thresholds, customer aliases, and commercial values are omitted.

    Source =
        Table.Combine(
            {
                ProviderATracking,
                ProviderBTracking
            }
        ),

    Typed =
        Table.TransformColumnTypes(
            Source,
            {
                {"Asset ID", type text},
                {"Location", type text},
                {"Landmark", type text},
                {"Status", type text},
                {"Speed", type number},
                {"Duration [h]", type number},
                {"Idle [h]", type number},
                {"Event Date", type datetime},
                {"Fleet", type text}
            }
        ),

    CleanAsset =
        Table.TransformColumns(
            Typed,
            {
                {
                    "Asset ID",
                    each
                        if _ = null then null
                        else Text.Upper(
                            Text.Replace(
                                Text.Trim(Text.Clean(Text.From(_))),
                                " ",
                                ""
                            )
                        ),
                    type text
                }
            }
        ),

    LatestTracking =
        Table.Group(
            Table.SelectRows(
                CleanAsset,
                each [Asset ID] <> null and [Asset ID] <> ""
            ),
            {"Asset ID"},
            {
                {
                    "Latest",
                    each Table.Max(_, "Event Date"),
                    type record
                }
            }
        ),

    ExpandedTracking =
        Table.ExpandRecordColumn(
            LatestTracking,
            "Latest",
            {
                "Location",
                "Landmark",
                "Status",
                "Speed",
                "Duration [h]",
                "Idle [h]",
                "Event Date",
                "Fleet"
            }
        ),

    MergeOrder =
        Table.NestedJoin(
            ExpandedTracking,
            {"Asset ID"},
            LatestAssetOrder,
            {"Asset_ID"},
            "Order",
            JoinKind.LeftOuter
        ),

    ExpandOrder =
        Table.ExpandTableColumn(
            MergeOrder,
            "Order",
            {"Order_ID", "Trip_ID", "Actual_Departure"},
            {"Order ID", "Trip ID", "Last Departure"}
        ),

    MergeSchedule =
        Table.NestedJoin(
            ExpandOrder,
            {"Trip ID"},
            RouteSchedule,
            {"Trip ID"},
            "Schedule",
            JoinKind.LeftOuter
        ),

    ExpandSchedule =
        Table.ExpandTableColumn(
            MergeSchedule,
            "Schedule",
            {"Lane", "Miles"},
            {"Lane", "Miles"}
        )

    // Production implementation continued with configured return-window,
    // exception, freshness, and financial/business rules.
in
    ExpandSchedule
