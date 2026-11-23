# Data dictionary: Connections (fact table)

Source: SP Energy Networks Open Data Portal, *Embedded Capacity Register* (ENA ECR template), CSV export.
Grain: one row per generation or storage site (≥1 MW) that is connected or accepted to connect.
Data as at: **19 Nov 2026**. Records loaded: **459** (395 unique projects after deduplication).

## Source fields (mapped by keyword in `FieldMap`)

| Standard name | Matched on (keywords) | Type | Description |
|---|---|---|---|
| Reference | "reference" (not "reinforcement") | Text | Unique site reference from the register |
| LicenceArea | "licence" | Text | Raw licence area value |
| ConnectionStatus | "connection status" | Text | Raw status, e.g. Connected / Accepted to Connect |
| EnergySource | "energy source 1" | Text | Primary energy source |
| Technology | "energy conversion technology 1" | Text | Primary conversion technology |
| GSP | "grid supply point" | Text | Grid Supply Point the site sits under |
| VoltageKV | "voltage" | Number | Point of connection voltage (kV) |
| ExportMW / ImportMW | "maximum export/import capacity" + "mw" | Number | Maximum export/import capacity (MW) |
| ConnectedMW | "already connected" | Number | Registered capacity already connected (MW) |
| AcceptedMW | "accepted to connect" + "capacity" | Number | Registered capacity accepted to connect (MW) |
| FlexibleConnection | "flexible" | Text | Whether the connection is flexible |
| DateConnected / DateAccepted / TargetEnergisationDate | "date connected" / "date accepted" / "target energisation" | Date | Key programme dates |
| Eastings / Northings | "eastings" / "northings" | Number | British National Grid coordinates |

Customer name and address fields are **excluded at load**. They aren't needed for reporting, so they're left out under the GDPR data minimisation principle.

## Derived fields

| Field | Logic | Purpose |
|---|---|---|
| RowID | Index 1..n | Stable key for the DQ exception table |
| LicenceAreaStd | SPD / SPM / Other, from LicenceArea text | One licence area standard |
| StatusGroup | "accepted" → Accepted to connect; "connected" → Connected; else Unknown/Other | One status standard |
| TechCategory | Keyword rules over Technology + EnergySource | One technology standard (see `DimTechnology`) |
| CapacityMW | ExportMW if > 0, else ConnectedMW / AcceptedMW by status | Single capacity measure |
| IsOverdue | Accepted to connect AND TargetEnergisationDate < DataAsAt | Programme exception |
| DaysOverdue | DataAsAt − TargetEnergisationDate (overdue rows only) | Exception severity |
| DaysAcceptedToTarget | TargetEnergisationDate − DateAccepted | Lead-time KPI |
| XYKey / GSPKey | Rounded coordinates / cleaned GSP name | Join keys for future mapping and GSP matching |
| DQ_* flags, DQ_IssueCount, DQ_Pass | See `data_quality_rules.md` | Data quality scoring |

## Dimension tables
- **DimDate**: CALENDARAUTO(3), UK financial year (Apr–Mar). Active on TargetEnergisationDate; inactive on DateAccepted and DateConnected.
- **DimLicenceArea**: SPD = SP Distribution (Central & Southern Scotland); SPM = SP Manweb (North Wales & North West England).
- **DimTechnology**: category → group (Renewable / Flexibility / Fossil & other / Unmapped).
- **DimStatus**: status groups with sort order.
- **DQ_Rules**: the rulebook. **DQ_Issues**: one row per failed rule per record.
