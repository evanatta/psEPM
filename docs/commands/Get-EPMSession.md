# Get-EPMSession

Shows the current session: base URI, API URI, auth method, user, token expiry, start time, elapsed time, last command and last error.

`-IncludeToken` adds the token so the object can be passed to `Use-EPMSession` later.

Notes:

- `TokenExpiresAt` is the token's `exp` claim in local time, or empty if the token is not a JWT.
- A client credentials session keeps its tenant ID, web app ID, and credential in module scope so the token can be renewed before it expires (see `New-EPMSession`). None of these are shown, with or without `-IncludeToken`.
- A session object saved with `-IncludeToken` and restored with `Use-EPMSession` carries only the token, so the restored session is not renewed.
