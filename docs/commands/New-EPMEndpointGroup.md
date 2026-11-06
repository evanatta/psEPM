# New-EPMEndpointGroup

Creates a static or dynamic endpoint group in a set.

API: `POST /Sets/{SetId}/Endpoints/Groups`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Name | Group name. Letters, numbers, spaces, `.`, `-`, `_` |
| Type | Static or Dynamic |
| Description | Optional description |
| Filter | Required for Dynamic, not allowed for Static. For example `platform EQ Windows AND is64Bit EQ true` |
| WhatIf, Confirm | Standard. ConfirmImpact is Medium |

Dynamic filter fields: siteName, version, is64Bit, model, network, platformVersion, organizationUnit, endpointType, platform, computerVendor, servicePack. Only `AND` is supported between predicates. `Get-EPMEndpointGroupValue` lists the values in a set.

Output: the created group as `psEPM.EndpointGroup` with the added `SetId` and `GroupId` properties. A static group returns `id`, `type`, `name`, `description`, and `membersCount`. A dynamic group returns `id`, `type`, `name`, `filter`, and `description` when set.

Example:

```powershell
New-EPMEndpointGroup -SetId $setId -Name 'Windows 64-bit' -Type Dynamic -Filter 'platform EQ Windows AND is64Bit EQ true'
```

Notes:

- The API reference example uses an `endpointGroups` path. The URL table path above is the one that works.
- A Dynamic group without a filter returns HTTP 500 from the API, so the command checks this before sending.
