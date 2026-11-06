# Remove-EPMPolicy

Deletes policies.

API: `DELETE /Sets/{SetId}/Policies/Server/{PolicyId}`, no body. Returns HTTP 204 with an empty body.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| PolicyId | One or more policy IDs, pipeline by property name |
| WhatIf, Confirm | Standard. ConfirmImpact is High, so PowerShell asks before deleting unless `-Confirm:$false` is passed |

Output: one `psEPM.PolicyRemoval` object per deleted policy with `SetId` and `PolicyId`.

Examples:

```powershell
Get-EPMPolicy -SetId $setId -Name 'Old test' | Remove-EPMPolicy -WhatIf
Remove-EPMPolicy -SetId $setId -PolicyId $policyId
```

Notes:

- The API reference says the result is a policy entity. The API returns 204 with no body.
- After a delete the policy no longer appears in `Get-EPMPolicy` searches, but `GET .../Policies/Server/{PolicyId}` still returns it (seen for at least 20 seconds). A second delete also returns 204, after which `GET` returns HTTP 404. A third delete returns HTTP 404 `EPM060001E` "Policy not found." Use a name search to confirm a delete.
- Do not use application group IDs here. Application groups have their own routes.
