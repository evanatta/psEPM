# Design

The module layout and conventions are modeled on psPAS (https://github.com/pspete/psPAS), the community PowerShell module for the Privileged Access Manager REST API. No psPAS code is used; the patterns below are reimplemented for EPM.

## Patterns taken from psPAS

| psPAS pattern | psEPM version |
| --- | --- |
| `Public/<Area>/` and `Private/` folders, one function per file, loader in the `.psm1` | Same. `psEPM.psm1` dot-sources every `.ps1` under `Private` and `Public` |
| Explicit `FunctionsToExport` list in the manifest | Same. A test checks every Public file is exported |
| Script-scope session object (`$psPASSession`) with base URI, start time, last command, last error | `$script:EPMSession` with BaseURI, ApiURI, AuthMethod, User, Token, StartTime, LastCommand, LastCommandTime, LastError |
| `New-PASSession`, `Get-PASSession`, `Use-PASSession`, `Close-PASSession` | `New-EPMSession`, `Get-EPMSession`, `Use-EPMSession`, `Close-EPMSession` |
| One private REST wrapper (`Invoke-PASRestMethod`) that every command calls, sets JSON content type, parses API errors into a terminating error | `Invoke-EPMRestMethod`, plus throttle retry with exponential backoff |
| Approved verbs and a product noun prefix (`Get-PASAccount`, `Add-PASSafeMember`) | `Verb-EPMNoun`, checked by a test |
| Parameter sets per API variation, `ValueFromPipelineByPropertyName` on IDs so `Get-X | Get-Y` works | Same. Output objects carry `SetId`, `EndpointId`, `PolicyId` so they pipe into the next command |
| `SupportsShouldProcess` with `ConfirmImpact` High on destructive commands | Planned for every write command; `-WhatIf` and `-Confirm` required on Move, Remove, Uninstall, Upgrade |
| Custom type names on output and `.Formats.ps1xml` default views | Type names added now (`psEPM.Set`, `psEPM.Endpoint`, `psEPM.Policy`); format files planned |
| Query string and filter helpers (`ConvertTo-QueryString`, `ConvertTo-FilterString`) | `ConvertTo-EPMQueryString`; filter builder planned |
| Pester tests per command with mocked REST calls | Same, Pester 5, no live calls in the repo |
| Markdown command help in `docs/` (platyPS) | Markdown help in `docs/commands` |
| CI runs PSScriptAnalyzer and Pester, then builds and publishes to the PowerShell Gallery | CI runs PSScriptAnalyzer and Pester on Windows PowerShell 5.1, PowerShell 7 on Windows and Linux. No publishing yet |
| Issue and pull request templates, CHANGELOG driven versions | Planned |

## psPAS patterns that do not fit EPM

- Version gating (`Assert-VersionRequirement`, Gen1/Gen2 parameter sets, self-hosted vs SaaS). EPM is SaaS only with one API version, except the `v2` endpoint group search. Version checks are not needed. `GET /Server/Version` can be exposed as a plain command.
- Many logon types (CyberArk, LDAP, RADIUS, SAML, Windows integrated, certificates, shared). EPM uses Identity OAuth2 client credentials. The legacy EPM logon (`/Auth/EPM/Logon`) and SAML logon are possible later additions, not the default.
- WebSession and cookie handling. EPM uses a bearer token only.
- Certificate skip and TLS options for on-premises vaults. Not needed for a SaaS API.
- Idle timeout tracking against the vault. The Identity token has its own `exp` claim; a token expiry check can be added later.
- Close-PASSession calls a logoff API. Identity OAuth2 tokens have no logoff, so `Close-EPMSession` clears local state only.
- Most PAM resources are single objects addressed by ID. Most EPM reads are `POST .../search` calls with a filter body and paging, so a shared paged search helper does most of the work.

## EPM specific rules built in

- Base path is `<regional API URL>/EPM/API`.
- Paging uses `offset` and `limit`; `limit` max is 1000. `Invoke-EPMPagedRequest` keeps requesting until a page is short, and `-First` stops early.
- Throttling returns HTTP 403 with error code `EPM050004E` (sometimes 429). The wrapper retries up to 5 times with 2, 4, 8, 16, 32 second waits.
- API errors come back as `[{ "ErrorCode": "...", "ErrorMessage": "..." }]` and are turned into one readable terminating error. The last error is also saved on the session.
- Filters are case sensitive. Lists use `IN a,b,c` without one big quoted string.
- All bodies are JSON. Some calls need `{}` instead of no body.

## Decisions

- No comments and no comment-based help in code files. Command help lives in `docs/commands/*.md`. A test fails if a code file contains a comment token.
- Windows PowerShell 5.1 compatible: no ternary, no null-coalescing, no `ForEach-Object -Parallel`, no `-SkipCertificateCheck`.
- Secrets come in as `PSCredential` or `SecureString`. The token lives only in module scope and is not shown by `Get-EPMSession` unless `-IncludeToken` is used.
- Write commands will default to `ConfirmImpact = 'High'` for anything that moves, deletes, uninstalls, or upgrades endpoints.
- MIT license, matching psPAS.
