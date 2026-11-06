# Get-EPMEndpointGroupValue

Lists the values of an endpoint attribute in a set. Use these values to build dynamic endpoint group filters.

API: `POST /Sets/{SetId}/Endpoints/Groups/values/search` with the body `{ "filter": "entity EQ <Entity>" }`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Entity | siteName, version, is64Bit, model, network, platformVersion, organizationUnit, endpointType, platform, computerVendor, servicePack |
| Filter | Extra filter joined with `AND`, for example `value EQ Windows` |

Output: one `psEPM.EndpointGroupValue` object per value with `value`, plus the added `SetId` and `Entity` properties. A set with no endpoints returns nothing.

Example:

```powershell
Get-EPMSet -Name 'Lab*' | Get-EPMEndpointGroupValue -Entity platformVersion
```

Notes:

- The API reference says the result is a list of endpoint IDs added to a group, and its example request shows a group members URL. The API returns a JSON array of `{ "value": "<text>" }` objects at the URL above.
- Values are strings, including `is64Bit`.
- An unknown entity name returns HTTP 200 with an empty array, not an error.
