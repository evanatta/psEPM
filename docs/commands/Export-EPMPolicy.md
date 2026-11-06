# Export-EPMPolicy

Exports the policies of a set as an `.epmp` policy file.

API: `POST /Sets/{SetId}/Policies/Server/Export` with `{ "ServerPolicyGroupType": <number> }`. This route is *undocumented*. It is not in the public API reference and may change. `POST /Sets/{SetId}/Policies/Export` is an alias.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| GroupType | Computer (0), User (1), or All (3). Default All |
| OutFile | Writes the raw `.epmp` content to this path |

Output: one `psEPM.PolicyExport` object with `SetId`, `GroupType`, `FileName` (from the `Content-Disposition` header, for example `Policies-06-Nov-26_10-40-00.epmp`), `Export` (the parsed file), and `Path` (the OutFile path, or empty).

The parsed file has `Policies`, `AppGroups`, `TrustSoftwareDistributors`, `UserAccessTokens`, and `EndUserUIs`. Each entry in `Policies` and `AppGroups` has the same fields as the `Policy` property returned by `Get-EPMPolicy -PolicyId` and `Get-EPMApplicationGroup -ApplicationGroupId`.

Examples:

```powershell
Export-EPMPolicy -SetId $setId -OutFile .\policies.epmp
(Get-EPMSet -Name 'Lab*' | Export-EPMPolicy -GroupType Computer).Export.Policies | Select-Object Name, PolicyType, IsActive
```

Notes:

- The response is JSON sent as `application/octet-stream`. The command reads the raw response and parses it.
- `ServerPolicyGroupType` 2 returns an empty file and 4 returns `EPM060016E`, so they are not offered. A string value returns HTTP 400, an empty body returns HTTP 500 `EPM060016E`, and `GET` returns HTTP 400.
- Application groups used by the exported policies are included in `AppGroups`.
