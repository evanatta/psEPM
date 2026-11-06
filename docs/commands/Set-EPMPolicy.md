# Set-EPMPolicy

Updates a policy.

API: `PUT /Sets/{SetId}/Policies/Server/{PolicyId}`.

Two ways to call it:

- **Merge** (default). Reads the policy, changes only the fields you pass, and sends the full definition back.
- **FromObject**. `-Policy` is a full replacement definition: a JSON string (sent unchanged), a hashtable, or an object. The output of `Get-EPMPolicy -PolicyId` can be passed directly; its `Policy` property is unwrapped.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| PolicyId | Policy ID, pipeline by property name. `Get-EPMPolicy` search and detail output both carry it |
| Name | New name (merge) |
| Description | New description (merge). An empty string clears it |
| IsActive | Activate or deactivate (merge). Only sent as a change when passed |
| Audit | Audit setting (merge) |
| Policy | Full definition (FromObject) |
| WhatIf, Confirm | Standard. ConfirmImpact is Medium. Nothing is read or sent under `-WhatIf` |

Output: the updated definition as `psEPM.PolicyDefinition` with the added `SetId` and `PolicyId` properties.

Examples:

```powershell
Get-EPMPolicy -SetId $setId -Name 'Allow notepad' | Set-EPMPolicy -Description 'Reviewed'
$detail = Get-EPMPolicy -SetId $setId -PolicyId $policyId
$detail.Policy.Name = 'Allow notepad (v2)'
Set-EPMPolicy -SetId $setId -PolicyId $policyId -Policy $detail
```

Notes:

- The update is a full replace. A body with only some fields returns HTTP 400 (for example "Missing mandatory parameter - PolicyType").
- `GET .../Policies/Server/{PolicyId}` wraps the definition: `{ CreatedDate, ModifiedDate, Order, OsType, Policy }`. `PUT` takes the definition itself. Sending it inside a `Policy` or `serverPolicy` wrapper returns HTTP 400.
- The policy ID in the URL is used. An `Id` in the body that is missing or different is ignored.
- `Applications` must stay a JSON array.
- An unknown or purged policy ID returns HTTP 404 `EPM060001E` "Policy not found."
