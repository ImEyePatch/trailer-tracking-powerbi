let
    //==================================================
    // PUBLIC PORTFOLIO SETTINGS
    //==================================================

    // Never commit real credentials or account identifiers.
    ApiUsername = "<USERNAME>",
    ApiPassword = "<PASSWORD>",
    ApiAccountId = "<ACCOUNT_ID>",

    WindowHours = 24,
    Limit = 2000,

    ApiBaseUrl = "https://example.invalid",
    TrafficPath = "api/asset/traffic",

    //==================================================
    // AUTHENTICATION
    //==================================================

    AuthString =
        "Basic " &
        Binary.ToText(
            Text.ToBinary(
                ApiUsername & ":" & ApiPassword,
                TextEncoding.Utf8
            ),
            BinaryEncoding.Base64
        ),

    //==================================================
    // QUERY WINDOW
    //==================================================

    NowUtc = DateTimeZone.UtcNow(),
    StartUtc = NowUtc - #duration(0, WindowHours, 0, 0),

    UnixEpoch =
        #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0),

    ToUnixMilliseconds =
        (dt as datetimezone) as number =>
            Number.RoundDown(
                Duration.TotalSeconds(dt - UnixEpoch) * 1000
            ),

    InitialStartAt = ToUnixMilliseconds(StartUtc),

    //==================================================
    // HELPERS
    //==================================================

    ToNullableDateTime =
        (value as any) as nullable datetime =>
            try DateTime.From(value) otherwise null,

    CleanAssetID =
        (value as any) as nullable text =>
            if value = null then
                null
            else
                let
                    cleaned = Text.Trim(Text.Clean(Text.From(value)))
                in
                    if cleaned = "" then null else cleaned,

    RequiredColumns = {
        "name",
        "eventDateTime",
        "city",
        "state",
        "landmarkName",
        "speed",
        "moving",
        "movingStartTime",
        "stoppedStartTime"
    },

    //==================================================
    // LATEST EVENT PER ASSET
    //==================================================

    ReduceToLatest =
        (inputTable as table) as table =>
            let
                validAssets =
                    Table.SelectRows(
                        inputTable,
                        each [name] <> null and [name] <> ""
                    ),

                grouped =
                    Table.Group(
                        validAssets,
                        {"name"},
                        {
                            {
                                "Latest",
                                (t as table) as record =>
                                    let
                                        withEventDate =
                                            Table.SelectRows(
                                                t,
                                                each [eventDateTime] <> null
                                            )
                                    in
                                        if Table.IsEmpty(withEventDate) then
                                            Table.First(t)
                                        else
                                            Table.Max(withEventDate, "eventDateTime"),
                                type record
                            }
                        }
                    ),

                expanded =
                    Table.ExpandRecordColumn(
                        grouped,
                        "Latest",
                        {
                            "eventDateTime",
                            "city",
                            "state",
                            "landmarkName",
                            "speed",
                            "moving",
                            "movingStartTime",
                            "stoppedStartTime"
                        }
                    )
            in
                expanded,

    //==================================================
    // GET ONE PAGE
    //==================================================

    GetTrafficPage =
        (startAt as number) as record =>
            let
                rawResponse =
                    Binary.Buffer(
                        Web.Contents(
                            ApiBaseUrl,
                            [
                                RelativePath = TrafficPath,
                                Headers = [
                                    Authorization = AuthString,
                                    Account = ApiAccountId,
                                    Accept = "application/json",
                                    #"Accept-Encoding" = "gzip"
                                ],
                                Query = [
                                    limit = Text.From(Limit),
                                    startAt = Text.From(startAt)
                                ],
                                Timeout = #duration(0, 0, 2, 0)
                            ]
                        )
                    ),

                response = Json.Document(rawResponse),

                data =
                    if Record.HasFields(response, "data") and response[data] <> null
                    then response[data]
                    else {},

                responseCount =
                    if Record.HasFields(response, "count") and response[count] <> null
                    then Number.From(response[count])
                    else List.Count(data),

                responseEndAt =
                    if Record.HasFields(response, "endAt") and response[endAt] <> null
                    then Number.From(response[endAt])
                    else startAt
            in
                [
                    StartAt = startAt,
                    EndAt = responseEndAt,
                    CountRows = responseCount,
                    Data = data
                ],

    //==================================================
    // PAGINATE RAW ROWS
    //==================================================

    Pages =
        List.Generate(
            () => GetTrafficPage(InitialStartAt),
            each [CountRows] > 0 and [EndAt] > [StartAt],
            each GetTrafficPage([EndAt]),
            each [Data]
        ),

    BufferedPages = List.Buffer(Pages),

    CombinedRows =
        if List.IsEmpty(BufferedPages)
        then {}
        else List.Combine(BufferedPages),

    RawTable =
        if List.IsEmpty(CombinedRows)
        then #table(RequiredColumns, {})
        else Table.FromRecords(CombinedRows, null, MissingField.UseNull),

    SelectedColumns =
        Table.SelectColumns(
            RawTable,
            RequiredColumns,
            MissingField.UseNull
        ),

    CleanKeysAndEventDate =
        Table.TransformColumns(
            SelectedColumns,
            {
                {"name", each CleanAssetID(_), type text},
                {"eventDateTime", each ToNullableDateTime(_), type datetime}
            }
        ),

    LatestPerAsset = ReduceToLatest(CleanKeysAndEventDate),

    ConvertedDates =
        Table.TransformColumns(
            LatestPerAsset,
            {
                {"movingStartTime", each ToNullableDateTime(_), type datetime},
                {"stoppedStartTime", each ToNullableDateTime(_), type datetime}
            }
        ),

    Renamed =
        Table.RenameColumns(
            ConvertedDates,
            {
                {"name", "Asset ID"},
                {"city", "City"},
                {"state", "State"},
                {"landmarkName", "Landmark"},
                {"speed", "Speed"},
                {"moving", "Moving"},
                {"movingStartTime", "Moving Start"},
                {"stoppedStartTime", "Stopped Start"},
                {"eventDateTime", "Event Date"}
            }
        ),

    AddLocation =
        Table.AddColumn(
            Renamed,
            "Location",
            each Text.Combine(
                List.Select(
                    List.Transform(
                        List.RemoveNulls({[City], [State]}),
                        each Text.Trim(Text.From(_))
                    ),
                    each _ <> ""
                ),
                ", "
            ),
            type text
        ),

    AddStatus =
        Table.AddColumn(
            AddLocation,
            "Status",
            each if [Moving] = true then "Moving" else "Stopped",
            type text
        ),

    AddDuration =
        Table.AddColumn(
            AddStatus,
            "Duration in current status",
            each
                if [Event Date] = null then null
                else if [Moving] = true then
                    if [Moving Start] = null then null
                    else [Event Date] - [Moving Start]
                else
                    if [Stopped Start] = null then null
                    else [Event Date] - [Stopped Start],
            type duration
        ),

    AddDurationHours =
        Table.AddColumn(
            AddDuration,
            "Duration [h]",
            each
                if [Duration in current status] = null then null
                else Duration.TotalHours([Duration in current status]),
            type number
        ),

    AddIdleHours =
        Table.AddColumn(
            AddDurationHours,
            "Idle [h]",
            each
                if [Event Date] = null or [Stopped Start] = null then null
                else Number.Round(
                    Duration.TotalHours([Event Date] - [Stopped Start]),
                    1
                ),
            type number
        ),

    AddFleet =
        Table.AddColumn(AddIdleHours, "Fleet", each "A", type text),

    Final =
        Table.SelectColumns(
            AddFleet,
            {
                "Asset ID",
                "Location",
                "Landmark",
                "Status",
                "Speed",
                "Duration in current status",
                "Duration [h]",
                "Idle [h]",
                "Event Date",
                "Fleet"
            }
        )
in
    Final
