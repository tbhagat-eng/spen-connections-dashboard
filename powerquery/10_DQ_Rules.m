// Query name: DQ_Rules   (Enable load) - the data quality rulebook, shown on the Data Quality page.
#table(
    type table [Rule = text, RuleName = text, Check = text, Severity = text, WhyItMatters = text],
    {
        {"DQ_MissingReference",     "Missing reference",        "Reference is blank",                                              "High",   "Record can't be traced back to the source system"},
        {"DQ_DuplicateReference",   "Duplicate reference",      "Same reference appears on more than one row",                     "High",   "Double-counts sites and MW"},
        {"DQ_MissingCapacity",      "Missing/invalid capacity", "Capacity MW is blank, zero or negative",                          "High",   "Understates pipeline and connected MW"},
        {"DQ_MissingLicenceArea",   "Missing licence area",     "Licence area blank or not SPD/SPM",                               "Medium", "Record drops out of licence-area reporting"},
        {"DQ_UnknownStatus",        "Unknown status",           "Connection status blank or not recognised",                       "Medium", "Can't tell connected from pipeline"},
        {"DQ_MissingTargetDate",    "Missing target date",      "Accepted-to-connect record has no target energisation date",      "Medium", "Can't be tracked against programme dates"},
        {"DQ_TargetBeforeAccepted", "Date sequence error",      "Target energisation date is before the date accepted",            "Medium", "Impossible timeline; distorts lead-time KPIs"},
        {"DQ_UnmappedTechnology",   "Unmapped technology",      "Technology label not covered by the category standard",           "Low",    "Falls into 'Unmapped' in technology views"},
        {"DQ_MissingCoordinates",   "Missing coordinates",      "Eastings/Northings blank or zero",                                "Low",    "Site can't be mapped"}
    }
)
