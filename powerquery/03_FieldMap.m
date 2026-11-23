// Query name: FieldMap   (Disable load)
// {Standard name, include keywords, exclude keywords}. Edit keywords here if Mapping_Check shows NOT FOUND.
// Customer name and address fields are deliberately NOT mapped: they aren't needed for reporting (GDPR data minimisation).
{
    {"Reference",              {"reference"},                       {"reinforcement"}},
    {"LicenceArea",            {"licence"},                         {}},
    {"ConnectionStatus",       {"connection status"},               {}},
    {"EnergySource",           {"energy source 1"},                 {}},
    {"Technology",             {"energy conversion technology 1"},  {"capacity"}},
    {"GSP",                    {"grid supply point"},               {}},
    {"VoltageKV",              {"voltage"},                         {}},
    {"ExportMW",               {"maximum export capacity", "mw"},   {"mva", "change"}},
    {"ImportMW",               {"maximum import capacity", "mw"},   {"mva", "change"}},
    {"ConnectedMW",            {"already connected"},               {}},
    {"AcceptedMW",             {"accepted to connect", "capacity"}, {}},
    {"FlexibleConnection",     {"flexible"},                        {}},
    {"DateConnected",          {"date connected"},                  {}},
    {"DateAccepted",           {"date accepted"},                   {}},
    {"TargetEnergisationDate", {"target energisation"},             {}},
    {"Eastings",               {"eastings"},                        {}},
    {"Northings",              {"northings"},                       {}}
}
