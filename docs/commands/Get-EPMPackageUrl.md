# Get-EPMPackageUrl

Gets a download URL for an agent package. API: `GET /Sets/{SetId}/packages/{PackageId}/Url`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| PackageId | Package ID, pipeline by property name |

Output: `SetId`, `PackageId` and `Url`.

```powershell
Get-EPMAgentPackage -SetId $setId -Platform Windows -Latest | Get-EPMPackageUrl
```

Notes:

- The API returns a JSON string: a pre-signed S3 URL. The tested tenant returned `X-Amz-Expires=18000` (5 hours); the docs example shows 72000.
- An unknown package ID returns HTTP 500, not 404.
- The docs example uses `/Computers/Packages/{Id}/Url` with a request body; that path is the removed legacy API and returns 404. No body is needed.
