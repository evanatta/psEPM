# Use-EPMSession

Switches to a session saved with `Get-EPMSession -IncludeToken`.

```powershell
$na = Get-EPMSession -IncludeToken
New-EPMSession -Token $other -BaseURI 'https://api-eu.epm.cyberark.cloud'
$na | Use-EPMSession
```
