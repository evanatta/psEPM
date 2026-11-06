# Roadmap

Status key: **Done** built and tested against a tenant. **Planned** not built yet. **Unavailable** the route returns 404 on the regional API host (`/API` and `/EPM/API`, GET and OPTIONS, checked November 2026), so no command is planned until it is reachable. Routes marked *undocumented* work but are not in the public API reference and may change.

All paths are under `<BaseURI>/API` on a regional API host such as `https://api-na.epm.cyberark.cloud`. A tenant manager host uses `<BaseURI>/EPM/API`.

## Session

| Command | API | Status |
| --- | --- | --- |
| New-EPMSession | `POST https://<TenantId>.id.cyberark.cloud/oauth2/token/<WebAppId>` | Done |
| Get-EPMSession / Use-EPMSession / Close-EPMSession | local | Done |
| New-EPMSession -Legacy | `POST /Auth/EPM/Logon` on the dispatcher | Unavailable |
| Get-EPMServerVersion | `GET /Server/Version` | Unavailable |

## Sets and accounts

| Command | API | Notes | Status |
| --- | --- | --- | --- |
| Get-EPMSet | `GET /Sets` | paged | Done |
| Get-EPMAccountUser | `GET /Account/Users` | the reference only documents `POST` (create user) | Unavailable |
| Add-EPMAccountUserSet | `POST /Account/Users/Bind` | ShouldProcess; write route, not probed | Planned |
| Get-EPMAccountAdminAudit | `GET /Account/AdminAudit` | deprecated in the reference; use SIEM integration | Unavailable |
| Set-EPMUserPassword | `POST /Users/Me/ChangePassword` | legacy auth only | Unavailable |

## Endpoints

| Command | API | Notes | Status |
| --- | --- | --- | --- |
| Get-EPMEndpoint | `POST /Sets/{SetId}/Endpoints/search` | filter, paging, `-Platform`, `-Name` | Done |
| Get-EPMEndpoint -EndpointId | `POST /Sets/{SetId}/Endpoints/{Id}/search` | `-InventoryType`; bad ID gives 500 | Done |
| Get-EPMEndpointInventory | `POST /Sets/{SetId}/Endpoints/inventory/{Type}` | `filter` required, empty for all; array result; filter on `endpointId`, `id` gives 500 | Done |
| Get-EPMEndpointSummary | `GET /Sets/{SetId}/Endpoints/Summary` | *undocumented* | Done |
| Update-EPMEndpoint | `POST /Sets/{SetId}/Endpoints/upgrade` | ShouldProcess High | Planned |
| Move-EPMEndpoint | `POST /Sets/{SetId}/Endpoints/moveset` | async; endpoint gets a new ID in the target set; ShouldProcess High | Planned |
| Remove-EPMEndpoint | `POST /Sets/{SetId}/Endpoints/delete` | ShouldProcess High | Planned |
| Uninstall-EPMEndpoint | `POST /Sets/{SetId}/Endpoints/uninstall` | ShouldProcess High | Planned |
| Get-EPMComputer | `GET /Sets/{SetId}/Computers` | legacy; use Get-EPMEndpoint | Unavailable |
| Get-EPMComputerGroup | `GET /Sets/{SetId}/ComputerGroups` | legacy; use endpoint groups | Unavailable |

## Endpoint groups

| Command | API | Notes | Status |
| --- | --- | --- | --- |
| Get-EPMEndpointGroup | `POST /v2/Sets/{SetId}/Endpoints/groups/search` | v2 preferred, v1 on 404; `filter` required, empty for all; no member list | Done |
| Get-EPMEndpointGroupValue | `POST /Sets/{SetId}/Endpoints/Groups/values/search` | `entity EQ <name>`; array of `{ value }` | Done |
| New-EPMEndpointGroup | `POST /Sets/{SetId}/Endpoints/Groups` | Dynamic requires `-Filter` | Done |
| Set-EPMEndpointGroup | `PUT /Sets/{SetId}/Endpoints/groups` | full replace; reads and merges first; type cannot change | Done |
| Remove-EPMEndpointGroup | `POST /Sets/{SetId}/Endpoints/groups/delete` | by ID or filter; empty filter rejected; ShouldProcess High | Done |
| Add-EPMEndpointGroupMember | `POST .../Groups/{GroupId}/members`, `.../members/ids` | by filter or IDs; one ID uses the IDs route; add by filter is asynchronous | Done |
| Remove-EPMEndpointGroupMember | `POST .../members/remove`, `.../members/ids/remove` | by filter or IDs; empty filter rejected; ShouldProcess High | Done |

## Policies

| Command | API | Notes | Status |
| --- | --- | --- | --- |
| Get-EPMPolicy | `POST /Sets/{SetId}/Policies/Server/Search`, `GET .../Server/{Id}` | empty body for all | Done |
| New-EPMPolicy | `POST /Sets/{SetId}/Policies/Server` | file name body as in the examples, inactive by default; or a full definition | Done |
| Set-EPMPolicy | `PUT /Sets/{SetId}/Policies/Server/{Id}` | full replace, no wrapper; merge reads first | Done |
| Remove-EPMPolicy | `DELETE /Sets/{SetId}/Policies/Server/{Id}` | 204; GET by ID still answers until a second delete; ShouldProcess High | Done |
| Export-EPMPolicy | `POST /Sets/{SetId}/Policies/Server/Export` | *undocumented* | Planned |
| Get-EPMPolicyElevation / Set-EPMPolicyElevation | `/Sets/{SetId}/Policies/Server/Elevate` | | Planned |
| Get-EPMApplicationGroup | `POST .../Policies/ApplicationGroups/Search`, `GET .../{Id}` | | Planned |
| New-, Set-, Remove-EPMApplicationGroup | `/Sets/{SetId}/Policies/ApplicationGroups` | | Planned |
| Get-EPMAgentConfiguration | `POST .../Policies/AgentConfiguration/Search`, `GET .../{Id}`, `GET .../Default` | | Planned |
| New-, Set-, Remove-EPMAgentConfiguration | `/Sets/{SetId}/Policies/AgentConfiguration` | | Planned |
| Get-EPMThreatProtectionPolicy | *undocumented* | | Planned |
| Get-EPMPolicyRecommendation | *undocumented* | | Planned |

## Events and audit

| Command | API | Notes | Status |
| --- | --- | --- | --- |
| Get-EPMEvent | `POST /Sets/{SetId}/Events/Search`, `GET /Events/{Id}` | `-DateFrom`, `-EventType`, paging | Planned |
| Get-EPMEventAggregation | `POST /Sets/{SetId}/Events/aggregations/search` | | Planned |
| Get-EPMPolicyAudit | `POST /Sets/{SetId}/policyaudits/search` | | Planned |
| Get-EPMPolicyAuditAggregation | `POST /Sets/{SetId}/policyaudits/aggregations/search` | | Planned |
| Get-EPMSignInAudit | `POST /Sets/{SetId}/signinaudits/search` | | Planned |
| Get-EPMSignInAuditAggregation | `POST /Sets/{SetId}/signinaudits/aggregations/search` | | Planned |
| Get-EPMAdminAudit | `GET /Sets/{SetId}/AdminAudit` | `-DateFrom` required | Planned |
| Get-EPMVideo | `POST /Sets/{SetId}/Videos/Search` | | Planned |

## Application catalog

| Command | API | Status |
| --- | --- | --- |
| Get-EPMApplicationCatalog | `POST /Sets/{SetId}/Files/Aggregations/search` | Planned |
| Get-EPMFileInstance | `POST /Sets/{SetId}/Files/FileInstances/Search` | Planned |

## Download center

| Command | API | Notes | Status |
| --- | --- | --- | --- |
| Get-EPMAgentPackage | `POST /Sets/{SetId}/packages/search` | `filter` required, empty for all; not paged | Done |
| Get-EPMEndpointPackage | `POST /Sets/{SetId}/Endpoints/Packages` | `{}` for all | Done |
| Get-EPMPackageConfiguration | `POST /Sets/{SetId}/packages/configuration` | key in `installationKey` header; `-OutFile` | Done |
| Get-EPMPackageUrl | `GET /Sets/{SetId}/packages/{Id}/Url` | signed S3 URL | Done |

## Reports

| Command | API | Status |
| --- | --- | --- |
| New-EPMReport | `POST /Sets/{SetId}/Reports` *undocumented* | Planned |

## Module work

- Format files for default table views
- Filter builder helper with safe quoting
- Token expiry check from the JWT `exp` claim with automatic renewal for client credentials
- CHANGELOG, issue and pull request templates
- Build step that packages the module, and optional PowerShell Gallery publishing
