// Query name: Mapping_Check   (Disable load) - open this FIRST. Every row should say OK.
// Any NOT FOUND: add or adjust keywords in FieldMap.
let
    Found  = List.Transform(FieldMap, each [StandardName = _{0}, SourceColumn = fnPick(ECR_Raw, _{1}, _{2})]),
    Result = Table.FromRecords(Found),
    Status = Table.AddColumn(Result, "Status", each if [SourceColumn] = null then "NOT FOUND" else "OK", type text)
in
    Status
