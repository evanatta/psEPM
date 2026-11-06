# Get-EPMEndpointSummary

Gets endpoint counts in a set, grouped by agent version and platform.

API: `GET /Sets/{SetId}/Endpoints/Summary`. This route is *undocumented*. It is not in the public API reference and may change.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |

Output: one `psEPM.EndpointSummary` object for each row of the response `summary` array, with the added `SetId` property. A set with no endpoints returns nothing.

| Property | Description |
| --- | --- |
| agentVersion | Agent version, for example `26.8.2.143` |
| platform | Windows, MacOS, or Linux |
| endpointsCount | Number of endpoints with this version and platform |
| versionSupported | Whether the agent version is still supported |
| SetId | Set ID |

Example:

```powershell
Get-EPMSet -Name 'Lab*' | Get-EPMEndpointSummary
```
