# Get-EPMPolicyRecommendation

Lists the policy recommendations of a set.

API: `GET /Sets/{SetId}/Policies/Recommendations`. This route is *undocumented*. It is not in the public API reference and may change.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |

Output: one `psEPM.PolicyRecommendation` object per entry in the response `Data` array with `Type` (for example `WellKnownApplications` or `WindowsRecommendedBlockRules`), `Priority`, `Publisher`, `Applications`, `Apps`, `AdminApps`, `NgApplications`, `AssociatedComputers`, and `Events`, plus `SetId`. A set with no recommendations returns nothing.

Example:

```powershell
Get-EPMSet -Name 'Lab*' | Get-EPMPolicyRecommendation | Select-Object SetId, Type, Priority
```

Notes:

- The response wrapper is `{ Data, FilteredCount, TotalCount, PrivilegeThreatProtectionPolicyNames, TypesToRequestFromEventService }`. The command returns the `Data` entries only.
- The route ignores `limit` and `offset`; all recommendations come back in one response.
