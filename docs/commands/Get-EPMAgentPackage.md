# Get-EPMAgentPackage

Lists the agent installation packages available to a set. API: `POST /Sets/{SetId}/packages/search`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Filter | Raw filter string, for example `platform EQ Windows` |
| PackageId | One or more package IDs, sent as `id IN <id>,<id>` |
| Platform | Windows, MacOS, Linux, Tools. One value is sent as `platform EQ`, more than one as `platform IN` |
| Latest | Return only packages with `packageType` `latest`, applied locally |

Output adds `SetId`, `PackageId` (same as `id`) and `Version` (`releaseVersion` as `major.minor.build.revision`), so results pipe into Get-EPMPackageUrl and Get-EPMPackageConfiguration.

Notes:

- `filter` is mandatory. An empty string returns all packages; `{}` or no body returns 400 `Missing mandatory parameter - filter.`
- Not paged. `offset` and `limit` are ignored and the full list comes back in one response.
- The documented `id IN 'a', 'b'` form (single quotes) returns HTTP 500. Unquoted (`id IN a,b`) or double-quoted IDs work. `id EQ` returns 500.
- Platform values are case sensitive: `platform EQ windows` returns no packages. `Tools` is not documented but works and returns the admin utilities.
- `releaseVersion` is documented as a string but returned as an object with `_major`, `_minor`, `_build`, `_revision`.
- `linuxAgentPublicKey` and `isDownloadStandaloneAgent` from the response are not returned.
- `GET` on the search URL returns 405.
