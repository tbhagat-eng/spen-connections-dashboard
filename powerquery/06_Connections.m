// Query name: Connections   (Enable load) - the fact table. One row per site in the Embedded Capacity Register.
let
    // ---------- 1. Map source columns to standard names ----------
    Found   = List.Transform(FieldMap, each {_{0}, fnPick(ECR_Raw, _{1}, _{2})}),
    Matched = List.Select(Found, each _{1} <> null),
    Kept    = Table.SelectColumns(ECR_Raw, List.Distinct(List.Transform(Matched, each _{1}))),
    Renamed = Table.RenameColumns(Kept, List.Select(List.Transform(Matched, each {_{1}, _{0}}), each _{0} <> _{1})),

    // ---------- 2. Cleanse: trim text; blanks and SPEN placeholders -> null ----------
    Placeholders = {"data not available", "data not applicable", "not available", "not applicable", "n/a", "-", "unknown", "tbc"},
    Trimmed = Table.TransformColumns(Renamed, {}, (v) =>
        if v is text then
            (let t = Text.Trim(v) in if t = "" or List.Contains(Placeholders, Text.Lower(t)) then null else t)
        else v),

    // ---------- 3. Data types (UK formats). Bad values become null and are caught by DQ rules ----------
    ToNum  = (v) => if v = null then null else try Number.From(v, "en-GB") otherwise null,
    ToDate = (v) => if v = null then null
                    else try Date.From(v, "en-GB")
                    otherwise (try Date.From(DateTimeZone.From(v)) otherwise null),
    NumCols  = List.Intersect({Table.ColumnNames(Trimmed), {"VoltageKV", "ExportMW", "ImportMW", "ConnectedMW", "AcceptedMW", "Eastings", "Northings"}}),
    DateCols = List.Intersect({Table.ColumnNames(Trimmed), {"DateConnected", "DateAccepted", "TargetEnergisationDate"}}),
    TypedNum = Table.TransformColumns(Trimmed, List.Transform(NumCols, (c) => {c, ToNum, type nullable number})),
    Typed    = Table.TransformColumns(TypedNum, List.Transform(DateCols, (c) => {c, ToDate, type nullable date})),

    // ---------- 4. Standardise categories (one data standard for messy labels) ----------
    Low = (v) => if v = null then "" else Text.Lower(Text.From(v)),
    AddRowID = Table.AddIndexColumn(Typed, "RowID", 1, 1, Int64.Type),
    AddLicence = Table.AddColumn(AddRowID, "LicenceAreaStd", each
        let t = Low(Record.FieldOrDefault(_, "LicenceArea", null)) in
            if t = "" then null
            else if Text.Contains(t, "manweb") or Text.Contains(t, "spm") then "SPM"
            else if Text.Contains(t, "distribution") or Text.Contains(t, "spd") then "SPD"
            else "Other", type nullable text),
    AddStatus = Table.AddColumn(AddLicence, "StatusGroup", each
        let s = Low(Record.FieldOrDefault(_, "ConnectionStatus", null)) in
            if s = "" then "Unknown"
            else if Text.Contains(s, "accepted") then "Accepted to connect"
            else if Text.Contains(s, "connected") then "Connected"
            else "Other", type text),
    AddTech = Table.AddColumn(AddStatus, "TechCategory", each
        let t = Low(Record.FieldOrDefault(_, "Technology", null)) & " " & Low(Record.FieldOrDefault(_, "EnergySource", null)) in
            if Text.Contains(t, "wind") then "Wind"
            else if Text.Contains(t, "solar") or Text.Contains(t, "photovoltaic") then "Solar"
            else if Text.Contains(t, "stor") or Text.Contains(t, "batter") then "Storage"
            else if Text.Contains(t, "hydrogen") then "Fossil & other"
            else if Text.Contains(t, "hydro") then "Hydro"
            else if Text.Contains(t, "bio") or Text.Contains(t, "waste") or Text.Contains(t, "landfill")
                 or Text.Contains(t, "anaerobic") or Text.Contains(t, "sewage") then "Bioenergy & waste"
            else if Text.Contains(t, "gas") or Text.Contains(t, "diesel") or Text.Contains(t, "oil")
                 or Text.Contains(t, "fossil") or Text.Contains(t, "chp") then "Fossil & other"
            else "Unmapped", type text),

    // ---------- 5. Capacity: export capacity, falling back to registered capacity ----------
    AddCapacity = Table.AddColumn(AddTech, "CapacityMW", each
        let
            exp = Record.FieldOrDefault(_, "ExportMW", null),
            con = Record.FieldOrDefault(_, "ConnectedMW", null),
            acc = Record.FieldOrDefault(_, "AcceptedMW", null)
        in
            if exp <> null and exp > 0 then exp
            else if [StatusGroup] = "Connected" then con
            else acc, type nullable number),

    // ---------- 6. Programme exceptions ----------
    AddAsAt = Table.AddColumn(AddCapacity, "DataAsAt", each DataAsAt, type date),
    AddOverdue = Table.AddColumn(AddAsAt, "IsOverdue", each
        let d = Record.FieldOrDefault(_, "TargetEnergisationDate", null) in
            [StatusGroup] = "Accepted to connect" and d <> null and d < DataAsAt, type logical),
    AddDaysOverdue = Table.AddColumn(AddOverdue, "DaysOverdue", each
        if [IsOverdue] then Duration.Days(DataAsAt - [TargetEnergisationDate]) else null, Int64.Type),
    AddLeadTime = Table.AddColumn(AddDaysOverdue, "DaysAcceptedToTarget", each
        let
            a = Record.FieldOrDefault(_, "DateAccepted", null),
            t = Record.FieldOrDefault(_, "TargetEnergisationDate", null)
        in
            if a <> null and t <> null then Duration.Days(t - a) else null, Int64.Type),

    // ---------- 7. Keys (coordinates, GSP name) ----------
    HasXY = List.Contains(Table.ColumnNames(AddLeadTime), "Eastings") and List.Contains(Table.ColumnNames(AddLeadTime), "Northings"),
    AddXYKey = if HasXY then Table.AddColumn(AddLeadTime, "XYKey", each
            if [Eastings] = null or [Northings] = null or [Eastings] <= 0 or [Northings] <= 0 then null
            else Text.From(Number.RoundDown([Eastings] + 0.5)) & "|" & Text.From(Number.RoundDown([Northings] + 0.5)), type nullable text)
        else AddLeadTime,
    HasGSP = List.Contains(Table.ColumnNames(AddXYKey), "GSP"),
    AddGspKey = if HasGSP then Table.AddColumn(AddXYKey, "GSPKey", each fnGspKey([GSP]), type nullable text) else AddXYKey,

    // ---------- 8. Duplicate check ----------
    HasRef = List.Contains(Table.ColumnNames(AddGspKey), "Reference"),
    RefCounts = if HasRef then Table.Group(AddGspKey, {"Reference"}, {{"RefCount", each Table.RowCount(_), Int64.Type}}) else null,
    WithRefCount = if HasRef
        then Table.ExpandTableColumn(Table.NestedJoin(AddGspKey, {"Reference"}, RefCounts, {"Reference"}, "RC", JoinKind.LeftOuter), "RC", {"RefCount"})
        else Table.AddColumn(AddGspKey, "RefCount", each 1, Int64.Type),

    // ---------- 8b. One reporting row per reference: keep the latest target date ----------
    SortedRefs = Table.Buffer(Table.Sort(WithRefCount, {{"Reference", Order.Ascending}, {"TargetEnergisationDate", Order.Descending}, {"RowID", Order.Ascending}})),
    AddSortIdx = Table.AddIndexColumn(SortedRefs, "SortIdx", 1, 1, Int64.Type),
    FirstIdx   = Table.Group(AddSortIdx, {"Reference"}, {{"FirstIdx", each List.Min([SortIdx]), Int64.Type}}),
    WithFirst  = Table.ExpandTableColumn(Table.NestedJoin(AddSortIdx, {"Reference"}, FirstIdx, {"Reference"}, "F", JoinKind.LeftOuter), "F", {"FirstIdx"}),
    AddPrimary = Table.AddColumn(WithFirst, "IsPrimaryRecord", each [Reference] = null or [SortIdx] = [FirstIdx], type logical),
    Dedupe     = Table.RemoveColumns(AddPrimary, {"SortIdx", "FirstIdx"}),

    // ---------- 9. Data quality rules (documented in DQ_Rules + docs/data_quality_rules.md) ----------
    DQ1 = Table.AddColumn(Dedupe, "DQ_MissingReference", each Record.FieldOrDefault(_, "Reference", null) = null, type logical),
    DQ2 = Table.AddColumn(DQ1, "DQ_DuplicateReference", each Record.FieldOrDefault(_, "Reference", null) <> null and [RefCount] > 1, type logical),
    DQ3 = Table.AddColumn(DQ2, "DQ_MissingCapacity", each [CapacityMW] = null or [CapacityMW] <= 0, type logical),
    DQ4 = Table.AddColumn(DQ3, "DQ_MissingLicenceArea", each [LicenceAreaStd] = null or [LicenceAreaStd] = "Other", type logical),
    DQ5 = Table.AddColumn(DQ4, "DQ_UnknownStatus", each [StatusGroup] = "Unknown" or [StatusGroup] = "Other", type logical),
    DQ6 = Table.AddColumn(DQ5, "DQ_MissingTargetDate", each
        [StatusGroup] = "Accepted to connect" and Record.FieldOrDefault(_, "TargetEnergisationDate", null) = null, type logical),
    DQ7 = Table.AddColumn(DQ6, "DQ_TargetBeforeAccepted", each [DaysAcceptedToTarget] <> null and [DaysAcceptedToTarget] < 0, type logical),
    DQ8 = Table.AddColumn(DQ7, "DQ_UnmappedTechnology", each [TechCategory] = "Unmapped", type logical),
    DQ9 = if HasXY then Table.AddColumn(DQ8, "DQ_MissingCoordinates", each [XYKey] = null, type logical) else DQ8,

    DQCols = List.Select(Table.ColumnNames(DQ9), each Text.StartsWith(_, "DQ_")),
    AddIssueCount = Table.AddColumn(DQ9, "DQ_IssueCount", each
        List.Count(List.Select(Record.FieldValues(Record.SelectFields(_, DQCols)), (x) => x = true)), Int64.Type),
    AddPass = Table.AddColumn(AddIssueCount, "DQ_Pass", each [DQ_IssueCount] = 0, type logical)
in
    AddPass
