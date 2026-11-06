# Get-EPMThreatProtectionPolicy

Lists the threat protection policies of a set.

API: `GET /Sets/{SetId}/Policies/ThreatProtection`. This route is *undocumented*. It is not in the public API reference and may change.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Name | Wildcard filter on `Name`, applied locally |
| Category | Wildcard filter on `CategoryName`, applied locally |

Output: one `psEPM.ThreatProtectionPolicy` object per policy with the API fields (`Id`, `Name`, `CategoryName`, `PolicyType`, `IsActive`, `Action`, `EPAction`, `AvailableActions`, `RuleId`, `ReleaseStatus`, `MinSupportedAgentVersion`, `Applications`, `Executors`, and targeting fields) plus `SetId` and `PolicyId` (from `Id`).

Examples:

```powershell
Get-EPMSet -Name 'Lab*' | Get-EPMThreatProtectionPolicy | Where-Object IsActive
Get-EPMThreatProtectionPolicy -SetId $setId -Category '*Credentials*' | Select-Object Name, IsActive, Action
```

Notes:

- The API returns a plain JSON array with every threat protection rule of the set, active or not. All rules report `PolicyType` 50.
