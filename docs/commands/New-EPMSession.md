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
