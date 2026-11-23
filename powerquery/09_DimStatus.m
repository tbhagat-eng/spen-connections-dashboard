// Query name: DimStatus   (Enable load)
#table(
    type table [StatusGroup = text, SortOrder = Int64.Type],
    {{"Connected", 1}, {"Accepted to connect", 2}, {"Unknown", 3}, {"Other", 4}}
)
