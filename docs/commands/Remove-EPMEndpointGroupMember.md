# Remove-EPMEndpointGroupMember

Removes endpoints from a static endpoint group, by endpoint ID or by filter. The endpoints themselves are not changed.

APIs:

- By ID: `POST /Sets/{SetId}/Endpoints/Groups/{GroupId}/members/ids/remove` with `{ "membersIds": ["<EndpointId>", ...] }`
- By filter: `POST /Sets/{SetId}/Endpoints/Groups/{GroupId}/members/remove` with `{ "filter": "<filter>" }`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| GroupId | Static group ID, pipeline by property name |
| EndpointId | One or more endpoint IDs, pipeline by property name |
| Filter | Member filter, for example `id EQ "<EndpointId>"`. Must not be empty |
| WhatIf, Confirm | Standard. ConfirmImpact is High, so PowerShell asks before removing unless `-Confirm:$false` is passed |

An empty or blank filter is rejected before any call. By ID, all IDs from the parameter and the pipeline are collected and sent as one request per set and group, up to 5,000 IDs per request.

Output: one `psEPM.EndpointGroupMemberChange` object per request with `SetId`, `GroupId`, `Action` (`Remove`), `Filter`, `RequestedIds`, and `AppliedIds`. By filter, `AppliedIds` holds the removed endpoint IDs returned by the API. By ID, the API returns only `true`, also for IDs that were not members, so `AppliedIds` is empty and `RequestedIds` lists what was sent.

Examples:

```powershell
Remove-EPMEndpointGroupMember -SetId $setId -GroupId $groupId -EndpointId $endpointId -WhatIf
Get-EPMEndpoint -SetId $setId -Name 'PC0' | Remove-EPMEndpointGroupMember -GroupId $groupId
```

Notes:

- These APIs apply to static groups.
- The API reference example for removing by IDs sends `DELETE .../members/ids` with a bare JSON array. That returns HTTP 400 ("Invalid UUID string: ids"). The URL table route `POST .../members/ids/remove` with `membersIds` is the one that works.
- The single-endpoint route `DELETE .../members/{EndpointId}` requires `Content-Type: application/json` with a `{}` body (HTTP 415 without it) and returns an empty body. This command uses the IDs route instead.
- Filter on `id`, not `endpointId`. `endpointId EQ` returns HTTP 500.
- Remove by filter acts on current members only. Members added by filter a moment earlier may not be there yet, because add by filter is asynchronous.
