# New-EPMReport

Generates an existing report definition in a set and returns the report.

API: `POST /Sets/{SetId}/Reports` with `{"reportId": "<ReportId>", "format": "JSON"}` *undocumented*

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| ReportId | ID (GUID) of an existing report definition, pipeline by property name |
| Format | `JSON` (default) or `CSV` |
| OutFile | Also write the raw response to this file |
| WhatIf, Confirm | Standard ShouldProcess switches. `-WhatIf` sends nothing |

Output: `psEPM.Report` with `SetId`, `ReportId`, `Format`, `FileName` (from `Content-Disposition`, if the API sends one), `Content`, and `Path` (the `-OutFile` path, otherwise empty). For `JSON`, `Content` is the parsed response when it parses, otherwise the text. For `CSV`, `Content` is the text.

Examples:

```powershell
New-EPMReport -SetId $setId -ReportId $reportId -WhatIf
New-EPMReport -SetId $setId -ReportId $reportId -Format CSV -OutFile .\report.csv
```

Notes:

- The route is not in the public API reference and may change. The reference documents no report API. The console's Reports page is where report definitions are created, run, and scheduled.
- No API lists or creates report definitions, so `ReportId` must be the ID of a definition that already exists in the set.
- An unknown `ReportId` returns HTTP 400 `EPM070010E`, and a malformed body returns HTTP 500 `EPM070003E`. Each failure writes a "Generate Report FAILURE" entry to the set's admin audit. The command checks that `ReportId` is a GUID and that `Format` is `JSON` or `CSV` before it sends anything, but it can't check that the definition exists.
- `GET /Sets/{SetId}/Reports` returns HTTP 405. `OPTIONS` reports `Allow: POST,OPTIONS`.
- Generating a report has side effects (an admin audit entry), so the command uses ShouldProcess with medium impact.
- A successful generate has not been run against a tenant, because no definition ID was available from documentation. The response handling follows `Export-EPMPolicy`: byte or text content, an optional `Content-Disposition` file name, and a UTF-8 byte order mark removed.
