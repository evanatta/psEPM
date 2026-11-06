# Remove-EPMApplicationGroup

Deletes application groups.

API: `DELETE /Sets/{SetId}/Policies/ApplicationGroups/{ApplicationGroupId}`, no body. Returns HTTP 204 with an empty body.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| ApplicationGroupId | One or more group IDs, pipeline by property name. Alias `PolicyId` |
| WhatIf, Confirm | Standard. ConfirmImpact is High, so PowerShell asks before deleting unless `-Confirm:$false` is passed |

Output: one `psEPM.ApplicationGroupRemoval` object per deleted group with `SetId` and `ApplicationGroupId`.

Examples:

```powershell
Get-EPMApplicationGroup -SetId $setId -Name 'Old editors' | Remove-EPMApplicationGroup -WhatIf
Remove-EPMApplicationGroup -SetId $setId -ApplicationGroupId $groupId
```

Notes:

- The API reference example uses `.../Policies/Server/ApplicationGroups/{Id}`. That returns HTTP 404 and does not delete. The working path has no `/Server`.
- After a delete the group no longer appears in a name search, but `GET .../ApplicationGroups/{Id}` still returns it. A second delete also returns 204, after which `GET` returns HTTP 404 `EPM060001E`. A third delete returns 404. Use a name search to confirm a delete. The command sends one delete per ID.
