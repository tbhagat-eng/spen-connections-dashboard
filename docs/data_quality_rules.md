# Data quality rules and results

Each source record is tested against every rule in Power Query (`Connections` steps DQ1–DQ9).
A record **passes** only if it fails no rules. **DQ score = records passing ÷ records checked.**

## Results (data as at 19 Nov 2026)
**Records checked: 459 · Passing all checks: 68.8% · Records with at least one issue: 143 · Total issues: 154**

| Rule | Check | Severity | Records failing | % of records |
|---|---|---|---|---|
| Duplicate reference | Same reference appears on more than one row | High | 125 | 27.2% |
| Missing target date | Accepted-to-connect record has no target energisation date | Medium | 15 | 3.3% |
| Date sequence error | Target energisation date before date accepted | Medium | 6 | 1.3% |
| Missing coordinates | Eastings/Northings blank or zero | Low | 6 | 1.3% |
| Unmapped technology | Technology not recorded / not in category standard | Low | 2 | 0.4% |
| Missing reference | Reference is blank | High | 0 | 0.0% |
| Missing/invalid capacity | Capacity MW blank, zero or negative | High | 0 | 0.0% |
| Missing licence area | Blank or not SPD/SPM | Medium | 0 | 0.0% |
| Unknown status | Status blank or not recognised | Medium | 0 | 0.0% |

## Findings
- **Duplicate references drive ~80% of issues.** 125 rows share 61 references (64 extra copies). Some duplicates conflict with each other: different target energisation dates, a project recorded as both *connected* and *accepted to connect* (e.g. 613540872, Ince), or one reference under two GSPs (e.g. 225603, Erskine and Johnstone).
- **Treatment:** reporting totals count each reference once (the row with the latest target date is kept). All duplicate rows stay flagged on the Data quality page for the data owner to resolve.
- **2 records have no technology recorded at source** (including a 99.4 MW pipeline project at Connahs Quay). These are flagged, not guessed.
- SPEN uses text placeholders ("data not available", "data not applicable"). These are standardised to blank at load, so they aren't treated as real values.

## Exceptions vs data quality
"Past target date" (23 accepted-to-connect projects, 955 MW) is a **business exception**, not a data error. It's reported on the Pipeline & delivery page.
