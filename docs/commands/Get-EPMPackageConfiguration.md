# Get-EPMPackageConfiguration

Gets the agent installation configuration and installation key for a package. API: `POST /Sets/{SetId}/packages/configuration`.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| PackageId | Package ID, pipeline by property name |
| Platform | Windows, MacOS, Linux. Pipeline by property name, also binds from `packageOS`. Sent in lower case |
| IncludePolicies | Sets `includePolicies` to true |
| OutFile | Writes the raw configuration to this path (UTF-8, no BOM) for the installer |

Output: `SetId`, `PackageId`, `Platform`, `InstallationKey`, `Configuration` (parsed JSON) and `Path`.

```powershell
Get-EPMAgentPackage -SetId $setId -Platform Windows -Latest |
    Where-Object name -eq 'VFAgentSetupX64.msi' |
    Get-EPMPackageConfiguration -OutFile .\agent.config
```

Notes:

- `POST` only. `GET` returns 405.
- The body needs `includePolicies`, `platform` and `packageId`. `{}` returns HTTP 500.
- The installation key is in the `installationKey` response header. Each call returns a new key and configuration; use them together.
- The configuration and key are secrets. Do not log or commit them.
- The docs example uses `/endpoints/packages/configuration`; the URL table and the API use `/packages/configuration`.
