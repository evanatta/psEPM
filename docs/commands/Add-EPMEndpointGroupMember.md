# Add-EPMEndpointGroupMember

Adds endpoints to a static endpoint group, by endpoint ID or by filter.

APIs:

- By ID: `POST /Sets/{SetId}/Endpoints/Groups/{GroupId}/members/ids` with `{ "membersIds": ["<EndpointId>", ...] }`
- By filter: `POST /Sets/{SetId}/Endpoints/Groups/{GroupId}/members` with `{ "filter": "<filter>", "override": false }`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| GroupId | Static group ID, pipeline by property name |
| EndpointId | One or more endpoint IDs, pipeline by property name |
| Filter | Endpoint filter, for example `name EQ "PC01"` or `id IN a,b`. Must not be empty |
| Override | Replace the group members with the endpoints that match the filter. Without it, matches are appended |
| WhatIf, Confirm | Standard. ConfirmImpact is Medium |

By ID, all IDs from the parameter and the pipeline are collected and sent as one request per set and group, up to 5,000 IDs per request. Duplicate IDs are sent once. One ID uses the same route as many.

Output: one `psEPM.EndpointGroupMemberChange` object per request with `SetId`, `GroupId`, `Action` (`Add`), `Filter`, `RequestedIds`, and `AppliedIds` (the endpoint IDs returned by the API).

Examples:

```powershell
Get-EPMEndpoint -SetId $setId -Name 'PC0' | Add-EPMEndpointGroupMember -GroupId $groupId
Add-EPMEndpointGroupMember -SetId $setId -GroupId $groupId -Filter 'name EQ "PC01"'
```

Notes:

- These APIs apply to static groups. Dynamic group members come from the group filter.
- By filter, the API returns the matching endpoint IDs at once, but the group is updated asynchronously. `membersCount` from `Get-EPMEndpointGroup` changed within a few seconds in testing.
- Filter on `id`, not `endpointId`. `endpointId EQ` returns HTTP 500 on the member APIs.
- An endpoint that is already a member is returned again and is not added twice.
- The API also has `includeAll` to add every endpoint in the set. This command does not send it.
- The single-endpoint route `POST .../members/{EndpointId}` returns an empty body and requires `Content-Type: application/json` with a `{}` body (HTTP 415 without it). This command uses the IDs route instead, which returns the added IDs.
