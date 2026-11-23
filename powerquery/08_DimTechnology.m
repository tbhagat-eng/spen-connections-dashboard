// Query name: DimTechnology   (Enable load)
#table(
    type table [TechCategory = text, Group = text, SortOrder = Int64.Type],
    {
        {"Wind",              "Renewable",   1},
        {"Solar",             "Renewable",   2},
        {"Hydro",             "Renewable",   3},
        {"Bioenergy & waste", "Renewable",   4},
        {"Storage",           "Flexibility", 5},
        {"Fossil & other",    "Fossil & other", 6},
        {"Unmapped",          "Unmapped",    7}
    }
)
