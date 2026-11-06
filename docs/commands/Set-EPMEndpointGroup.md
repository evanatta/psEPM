# Set-EPMEndpointGroup

Updates the name, description, or dynamic filter of an endpoint group.

API: `PUT /Sets/{SetId}/Endpoints/groups` with the group ID in the body as `id`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| GroupId | Group ID, pipeline by property name |
| Name | New name |
| Description | New description. An empty string clears it |
| Filter | New filter, Dynamic groups only |
| WhatIf, Confirm | Standard. ConfirmImpact is Medium |

The update replaces the whole group. The command reads the group with `Get-EPMEndpointGroup` first, applies the parameters you pass, and sends `id`, `type`, `name`, `description`, and for a dynamic group `filter`. Fields you do not pass keep their current values. Nothing is read or sent under `-WhatIf`.

Output: the updated group as `psEPM.EndpointGroup` with `id`, `type`, `name`, `description`, `membersCount` (static), `filter` (dynamic), `updated`, and the added `SetId` and `GroupId` properties.

Example:

```powershell
Get-EPMEndpointGroup -SetId $setId -Name 'Lab' | Set-EPMEndpointGroup -Description 'Lab machines'
```

Notes:

- The API reference examples send PUT to `.../groups/<GroupId>/members/ids`, which returns HTTP 405. The URL table path above is the one that works.
- The API needs `id`, `type`, and `name` (HTTP 400 without them). An omitted `description` is cleared. A dynamic group sent without `filter` returns HTTP 500.
- The group type cannot be changed. Changing Static to Dynamic returns HTTP 500, so the command has no `-Type` parameter. Create a new group instead.
- An unknown group ID returns HTTP 500 from the API. The command checks the group exists first and reports it as not found.
