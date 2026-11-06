# Design

The module layout and conventions are modeled on psPAS (https://github.com/pspete/psPAS), the community PowerShell module for the Privileged Access Manager REST API. No psPAS code is used; the patterns below are reimplemented for EPM.

## Patterns taken from psPAS

| psPAS pattern | psEPM version |
| --- | --- |
| `Public/<Area>/` and `Private/` folders, one function per file, loader in the `.psm1` | Same. `psEPM.psm1` dot-sources every `.ps1` under `Private` and `Public` |
| Explicit `FunctionsToExport` list in the manifest | Same. A test checks every Public file is exported |
| Script-scope session object (`$psPASSession`) with base URI, start time, last command, last error | `$script:EPMSession` with BaseURI, ApiURI, AuthMethod, User, Token, TokenExpiresAt, StartTime, LastCommand, LastCommandTime, LastError, plus TenantId, WebAppId, and Credential for client credentials renewal |
| `New-PASSession`, `Get-PASSession`, `Use-PASSession`, `Close-PASSession` | `New-EPMSession`, `Get-EPMSession`, `Use-EPMSession`, `Close-EPMSession` |
| One private REST wrapper (`Invoke-PASRestMethod`) that every command calls, sets JSON content type, parses API errors into a terminating error | `Invoke-EPMRestMethod`, plus throttle retry with exponential backoff |
| Approved verbs and a product noun prefix (`Get-PASAccount`, `Add-PASSafeMember`) | `Verb-EPMNoun`, checked by a test |
| Parameter sets per API variation, `ValueFromPipelineByPropertyName` on IDs so `Get-X | Get-Y` works | Same. Output objects carry `SetId`, `EndpointId`, `PolicyId` so they pipe into the next command |
| `SupportsShouldProcess` with `ConfirmImpact` High on destructive commands | Every write command. Create and update use Medium, delete uses High. Move, Uninstall, and Upgrade will use High |
| Custom type names on output and `.Formats.ps1xml` default views | Type names on every output (`psEPM.Set`, `psEPM.Endpoint`, `psEPM.Policy`, and others). `psEPM.Format.ps1xml`, loaded through `FormatsToProcess`, has default table views for the list types |
| Query string and filter helpers (`ConvertTo-QueryString`, `ConvertTo-FilterString`) | `ConvertTo-EPMQueryString` (private) and `ConvertTo-EPMFilter` (exported) |
| Pester tests per command with mocked REST calls | Same, Pester 5, no live calls in the repo |
| Markdown command help in `docs/` (platyPS) | Markdown help in `docs/commands` |
| CI runs PSScriptAnalyzer and Pester, then builds and publishes to the PowerShell Gallery | CI runs PSScriptAnalyzer and Pester on Windows PowerShell 5.1, PowerShell 7 on Windows and Linux. No publishing yet |
| Issue and pull request templates, CHANGELOG driven versions | Planned |

## psPAS patterns that do not fit EPM

- Version gating (`Assert-VersionRequirement`, Gen1/Gen2 parameter sets, self-hosted vs SaaS). EPM is SaaS only with one API version, except the `v2` endpoint group search. Version checks are not needed. `GET /Server/Version` can be exposed as a plain command.
- Many logon types (CyberArk, LDAP, RADIUS, SAML, Windows integrated, certificates, shared). EPM uses Identity OAuth2 client credentials. The legacy EPM logon (`/Auth/EPM/Logon`) and SAML logon are possible later additions, not the default.
- WebSession and cookie handling. EPM uses a bearer token only.
- Certificate skip and TLS options for on-premises vaults. Not needed for a SaaS API.
- Idle timeout tracking against the vault. The Identity token has its own `exp` claim instead, which the module checks before each call (see below).
- Close-PASSession calls a logoff API. Identity OAuth2 tokens have no logoff, so `Close-EPMSession` clears local state only.
- Most PAM resources are single objects addressed by ID. Most EPM reads are `POST .../search` calls with a filter body and paging, so a shared paged search helper does most of the work.

## EPM specific rules built in

- Base path is `<regional API URL>/API`, the same pattern as the example scripts. A tenant manager host (`*.epm.cyberark.com`) uses `/EPM/API`.
- Paging uses `offset` and `limit`; `limit` max is 1000. `Invoke-EPMPagedRequest` keeps requesting until a page is short, and `-First` stops early.
- Event searches page with `nextCursor` instead (`Invoke-EPMPagedRequest -Cursor`). The first cursor is `start`, and each returned cursor is URL-encoded. Paging stops at `filteredCount`, on an empty cursor, or when the API returns the same cursor or page again, and warns when fewer than `filteredCount` results came back.
- Throttling returns HTTP 403 with error code `EPM050004E` (sometimes 429). The wrapper retries up to 5 times with 2, 4, 8, 16, 32 second waits.
- API errors come back as `[{ "ErrorCode": "...", "ErrorMessage": "..." }]` and are turned into one readable terminating error. The last error is also saved on the session.
- Filters are case sensitive. Lists use `IN a,b,c` without one big quoted string. `ConvertTo-EPMFilter` quotes string values, writes dates as unquoted UTC ISO 8601, and rejects values that contain a double quote or end with a backslash.
- Before each API call, `Assert-EPMSession` reads the JWT `exp` claim. A token that is not a JWT is not checked. A token that has expired or expires within 60 seconds is renewed for a client credentials session, using the same private token request as `New-EPMSession`. A `-Token` session throws and asks for a new session.
- All bodies are JSON. Some calls need `{}` instead of no body.

## Decisions

- No comments and no comment-based help in code files. Command help lives in `docs/commands/*.md`. A test fails if a code file contains a comment token.
- Windows PowerShell 5.1 compatible: no ternary, no null-coalescing, no `ForEach-Object -Parallel`, no `-SkipCertificateCheck`.
- Secrets come in as `PSCredential` or `SecureString`. The token lives only in module scope and is not shown by `Get-EPMSession` unless `-IncludeToken` is used. A client credentials session also keeps its `PSCredential` in module scope for renewal. It is never shown by `Get-EPMSession`, and `Close-EPMSession` clears it.
- Write commands default to `ConfirmImpact = 'High'` for anything that moves, deletes, uninstalls, or upgrades endpoints.
- Write command pattern: validate parameters and build the body first, then call `$PSCmdlet.ShouldProcess(<target>, <action>)` and return if it is false, then call the API. The target names the set and the object or filter, so `-WhatIf` output is readable. Nothing is sent to the API under `-WhatIf`, including reads.
- Commands that delete by filter never send an empty filter. They require an ID or a non-empty filter and throw otherwise.
- Update calls that replace the whole object read the current object first and merge the changed parameters, so omitted fields are kept.
- MIT license, matching psPAS.
