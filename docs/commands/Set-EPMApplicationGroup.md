# Set-EPMApplicationGroup

Updates an application group.

API: `PUT /Sets/{SetId}/Policies/ApplicationGroups/{ApplicationGroupId}`.

Two ways to call it:

- **Merge** (default). Reads the group, changes only the fields you pass, and sends the full definition back.
- **FromObject**. `-Policy` is a full replacement definition. The output of `Get-EPMApplicationGroup -ApplicationGroupId` can be passed directly; its `Policy` property is unwrapped.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| ApplicationGroupId | Group ID, pipeline by property name. Alias `PolicyId` |
| Name | New name (merge) |
| Description | New description (merge). An empty string clears it |
| Policy | Full definition (FromObject) |
| WhatIf, Confirm | Standard. ConfirmImpact is Medium. Nothing is read or sent under `-WhatIf` |

Output: the updated definition as `psEPM.ApplicationGroupDefinition` with `SetId` and `ApplicationGroupId`.

Example:

```powershell
Get-EPMApplicationGroup -SetId $setId -Name 'Editors' | Set-EPMApplicationGroup -Description 'Approved text editors'
```

Notes:

- The update is a full replace and takes the definition itself. A partial body or a body inside a `Policy` wrapper returns HTTP 400 "Missing mandatory parameter - PolicyType".
- A body without `Applications` is accepted and removes every application from the group. Merge mode always sends the current applications.
- Applications carry an `id`. Sending an application `id` that is no longer in the group returns HTTP 400 "You cannot create a new application while providing an Id". Read the group again before a full replace if it was changed elsewhere.
