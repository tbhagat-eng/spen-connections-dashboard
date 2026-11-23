// Query name: fnGspKey   (Disable load)
// Builds a matching key from a GSP name, so "Smeaton GSP 132kV" and "SMEATON" reconcile to the same key.
(v as any) as nullable text =>
let
    t     = if v = null then "" else Text.Upper(Text.From(v)),
    clean = Text.Remove(t, {"(", ")", ".", ",", "-", "/", "'", "_"}),
    stop  = {"GSP", "GRID", "SUPPLY", "POINT", "SUBSTATION", "SS", "132KV", "275KV", "400KV", "33KV", "11KV"},
    words = List.Select(Text.Split(clean, " "), each _ <> "" and not List.Contains(stop, _)),
    key   = Text.Combine(words, " ")
in
    if key = "" then null else key
