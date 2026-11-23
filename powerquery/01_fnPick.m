// Query name: fnPick   (Disable load: right-click query > untick "Enable load")
// Finds the source column whose name contains ALL "include" keywords and NONE of the "exclude" keywords.
// Works whether the export uses labels ("Maximum Export Capacity (MW)") or field names ("maximum_export_capacity_mw").
(tbl as table, include as list, exclude as list) as nullable text =>
let
    Norm = (t as text) as text =>
        Text.Lower(Text.Combine(List.Select(Text.SplitAny(t, " _-()/:&,."), each _ <> ""), " ")),
    Hits = List.Select(
        Table.ColumnNames(tbl),
        (c) =>
            List.AllTrue(List.Transform(include, (k) => Text.Contains(Norm(c), k)))
            and not List.AnyTrue(List.Transform(exclude, (k) => Text.Contains(Norm(c), k)))
    )
in
    if List.IsEmpty(Hits) then null else List.First(Hits)
