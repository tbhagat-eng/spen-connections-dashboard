// Query name: ECR_Raw   (Disable load)
// Loads the CSV and auto-detects the delimiter (Opendatasoft exports usually use semicolons).
let
    Raw       = File.Contents(FilePath),
    FirstLine = List.First(Lines.FromBinary(Raw, null, null, 65001)),
    Delim     = if List.Count(Text.Split(FirstLine, ";")) > List.Count(Text.Split(FirstLine, ",")) then ";" else ",",
    Source    = Csv.Document(Raw, [Delimiter = Delim, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted  = Table.PromoteHeaders(Source, [PromoteAllScalars = true])
in
    Promoted
