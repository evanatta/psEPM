# New-EPMSession

Starts a session with the EPM API.

## Syntax

```
New-EPMSession -TenantId <string> -WebAppId <string> -Credential <PSCredential> -BaseURI <string> [-PassThru]
New-EPMSession -Token <SecureString> -BaseURI <string> [-PassThru]
```

## Parameters

| Name | Description |
| --- | --- |
| TenantId | Identity tenant ID, the first label of `<TenantId>.id.cyberark.cloud` |
| WebAppId | Identity OAuth2 web app ID |
| Credential | Service user name and secret |
| Token | An existing bearer token, for testing |
| BaseURI | Regional EPM API URL, for example `https://api-na.epm.cyberark.cloud` |
| PassThru | Return the session info |

## Notes

The token request posts `grant_type=client_credentials` to `https://<TenantId>.id.cyberark.cloud/oauth2/token/<WebAppId>` with a Basic header built from `user:secret` (UTF-8, Base64). That matches the example scripts. Use the same regional API URL the examples ask for as `-BaseURI`, for example `https://api-na.epm.cyberark.cloud`. The module then calls `{BaseURI}/API`. If you pass a tenant manager host such as `https://na123.epm.cyberark.com`, it calls `{BaseURI}/EPM/API` instead. The token is kept in module scope only and is never written to disk.

## Token expiry and renewal

- If the token is a JWT, the module reads its `exp` claim. It does not verify the signature, and it never writes the token or its claims to output. `Get-EPMSession` shows the expiry as `TokenExpiresAt` (local time). A token that is not a JWT is not checked.
- Before every API call, the module checks whether the token has expired or expires within 60 seconds.
- A client credentials session (`-TenantId`, `-WebAppId`, `-Credential`) keeps the tenant ID, web app ID, and credential in module scope so it can renew. When the token is close to expiry, it requests a new one with the same token request as above and continues the call. The credential is not shown by `Get-EPMSession`, even with `-IncludeToken`. `Close-EPMSession` clears it.
- A session opened with `-Token` is not renewed. Once its JWT is expired or within 60 seconds of expiry, API calls throw an error asking you to run `New-EPMSession` again.
- A session restored with `Use-EPMSession` has no stored credential, so it is not renewed either.
