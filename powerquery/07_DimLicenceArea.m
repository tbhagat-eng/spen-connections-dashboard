// Query name: DimLicenceArea   (Enable load)
#table(
    type table [LicenceAreaStd = text, LicenceAreaName = text, Region = text],
    {
        {"SPD",   "SP Distribution", "Central & Southern Scotland"},
        {"SPM",   "SP Manweb",       "North Wales & North West England"},
        {"Other", "Other / unknown", "-"}
    }
)
