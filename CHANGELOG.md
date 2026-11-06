# Changelog

All notable changes to psEPM are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/). The version in `psEPM/psEPM.psd1` matches the latest entry.

## Unreleased

## 0.1.0 - 2026-11-06

First version. Covers the documented EPM REST API. Routes that return 404 on the regional API host are listed as Unavailable in [ROADMAP.md](ROADMAP.md).

### Session

- `New-EPMSession` with Identity OAuth2 client credentials (`-TenantId`, `-WebAppId`, `-Credential`) or an existing token (`-Token`). Uses `/API` on a regional API host and `/EPM/API` on a tenant manager host.
- `Get-EPMSession`, `Use-EPMSession`, `Close-EPMSession`. The token is kept in module scope and shown only with `-IncludeToken`.
- The JWT `exp` claim is checked before each call. Client credentials sessions renew the token within 60 seconds of expiry. `-Token` sessions throw and ask for a new session.

### Sets

- `Get-EPMSet` by name or ID.

### Endpoints

- `Get-EPMEndpoint` (search and details), `Get-EPMEndpointInventory`, `Get-EPMEndpointSummary`.
- `Update-EPMEndpoint`, `Move-EPMEndpoint`, `Remove-EPMEndpoint`, `Uninstall-EPMEndpoint`, with `ConfirmImpact` High. Each requires an endpoint ID or a non-empty filter and never sends `includeAll: true`.

### Endpoint groups

- `Get-EPMEndpointGroup`, `Get-EPMEndpointGroupValue`, `New-EPMEndpointGroup`, `Set-EPMEndpointGroup`, `Remove-EPMEndpointGroup`.
- `Add-EPMEndpointGroupMember`, `Remove-EPMEndpointGroupMember` for static groups, by ID or filter.

### Policies

- `Get-EPMPolicy`, `New-EPMPolicy`, `Set-EPMPolicy` (merge or full replace), `Remove-EPMPolicy`, `Export-EPMPolicy`.
- `Get-EPMApplicationGroup`, `New-EPMApplicationGroup`, `Set-EPMApplicationGroup`, `Remove-EPMApplicationGroup`.
- `Get-EPMAgentConfiguration` (search, details, product default), `New-EPMAgentConfiguration`, `Set-EPMAgentConfiguration`, `Remove-EPMAgentConfiguration`.
- `Set-EPMPolicyElevation` to approve or reject a temporary elevation request.
- `Get-EPMThreatProtectionPolicy`, `Get-EPMPolicyRecommendation`.

### Events and audit

- `Get-EPMEvent`, `Get-EPMEventAggregation`, `Get-EPMPolicyAudit`, `Get-EPMPolicyAuditAggregation`, `Get-EPMSignInAudit`, `Get-EPMSignInAuditAggregation`, with `nextCursor` paging and date, event type, and raw filters.
- `Get-EPMAdminAudit` for a date window, `Get-EPMVideo`.

### Application catalog

- `Get-EPMApplicationCatalog`, `Get-EPMFileInstance`.

### Download center

- `Get-EPMAgentPackage`, `Get-EPMEndpointPackage`, `Get-EPMPackageConfiguration`, `Get-EPMPackageUrl`.

### Reports

- `New-EPMReport` runs an existing report definition (undocumented route).

### Module

- `ConvertTo-EPMFilter` builds filter strings. It quotes string values, writes `IN` lists without one big quoted string, writes dates as UTC ISO 8601, and rejects values that contain a double quote.
- Default table views in `psEPM.Format.ps1xml` for sets, endpoints, groups, policies, application groups, agent configurations, events, audits, catalog rows, and packages.
- Every write command supports `-WhatIf` and `-Confirm`. Create and update use `ConfirmImpact` Medium; delete, move, uninstall, upgrade, and elevation use High.
- One REST wrapper with throttle retry (HTTP 429 and `EPM050004E`) and readable API errors.
- Windows PowerShell 5.1 and PowerShell 7 support, Pester tests with mocked calls, PSScriptAnalyzer, and command help in `docs/commands`.
- `build/Build.ps1` packages the module for the PowerShell Gallery, with optional publishing.

