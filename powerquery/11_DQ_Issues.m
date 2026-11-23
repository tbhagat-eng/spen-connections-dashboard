// Query name: DQ_Issues   (Enable load) - one row per failed rule per record (long format for charts + exception list).
let
    Source   = Connections,
    FlagCols = List.Select(Table.ColumnNames(Source), each Text.StartsWith(_, "DQ_") and _ <> "DQ_IssueCount" and _ <> "DQ_Pass"),
    Kept     = Table.SelectColumns(Source, {"RowID"} & FlagCols),
    Long     = Table.UnpivotOtherColumns(Kept, {"RowID"}, "Rule", "Failed"),
    Failed   = Table.SelectRows(Long, each [Failed] = true),
    Result   = Table.TransformColumnTypes(Table.RemoveColumns(Failed, {"Failed"}), {{"RowID", Int64.Type}, {"Rule", type text}})
in
    Result
