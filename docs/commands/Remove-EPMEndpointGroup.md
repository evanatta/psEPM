# Remove-EPMEndpointGroup

Deletes endpoint groups by ID or by filter.

API: `POST /Sets/{SetId}/Endpoints/groups/delete` with the body `{ "filter": "<filter>" }`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| GroupId | One or more group IDs, pipeline by property name. One ID sends `id EQ "<value>"`, several send `id IN a,b` |
| Filter | Filter on `id`, `name`, `type`, or `description`. Joined to the GroupId clause with `AND`. Required when GroupId is not given |
| WhatIf, Confirm | Standard. ConfirmImpact is High, so PowerShell asks before deleting unless `-Confirm:$false` is passed |

An empty or blank filter is rejected before any call. An empty filter could match every group in the set. The `-WhatIf` and `-Confirm` text shows the set and the exact filter.

Output: one `psEPM.EndpointGroupRemoval` object per call with `SetId`, `Filter`, `AppliedIds` (the deleted group IDs), and `AttachedPolicies` (as returned by the API, empty `{}` for groups not used by policies). A warning is written when nothing matched.

Examples:

```powershell
Remove-EPMEndpointGroup -SetId $setId -GroupId $groupId -WhatIf
Get-EPMEndpointGroup -SetId $setId -Name 'Old' | Remove-EPMEndpointGroup
```

Notes:

- The API reference is wrong. Its URL table shows `POST .../Endpoints/groups`, which is the create call, and its example shows `DELETE .../Endpoints/groups`, which returns HTTP 405. The working call is `POST .../Endpoints/groups/delete`.
- A filter that matches nothing returns HTTP 200 with an empty `appliedIds`.
