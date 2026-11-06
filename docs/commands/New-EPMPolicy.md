# New-EPMPolicy

Creates a policy in a set.

API: `POST /Sets/{SetId}/Policies/Server`. Returns HTTP 201 with the policy definition.

Two ways to call it:

- **File name** (default). Builds the same body as the example script: an application policy for one file name.
- **FromObject**. `-Policy` is a full policy definition as a JSON string, a hashtable, or an object. A JSON string is sent unchanged. An object is converted to JSON with arrays kept as arrays.

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Name | Policy name (file name set) |
| FileName | File name to match, for example `notepad.exe` (file name set) |
| Description | Optional description (file name set) |
| PolicyType | Default 11 (file name set) |
| Action | Default 1 (file name set) |
| Audit | Default `$false` (file name set) |
| IsActive | Default `$false` (file name set). The policy is created inactive unless you pass `-IsActive $true` |
| IsAppliedToAllComputers | Default `$true` (file name set). `$false` needs targets, or the API returns HTTP 400 "at least one computer must be specified" |
| Policy | Full definition (FromObject set). Nothing is added, so `IsActive` follows the API default when omitted |
| WhatIf, Confirm | Standard. ConfirmImpact is Medium |

File name body:

```json
{
  "Name": "<Name>", "PolicyType": 11, "Action": 1, "Description": "<Description>",
  "IsActive": false, "IsAppliedToAllComputers": true, "Audit": false,
  "Applications": [
    { "applicationType": 3, "displayName": "<FileName>",
      "patterns": { "FILE_NAME": { "@type": "FileName", "isEmpty": false, "compareAs": 0, "caseSensitive": false, "content": "<FileName>" } } }
  ]
}
```

Output: the created definition as `psEPM.PolicyDefinition` (`Id`, `Name`, `PolicyType`, `Action`, `IsActive`, `Applications`, `Executors`, and the other policy fields) with the added `SetId` and `PolicyId` properties.

Examples:

```powershell
New-EPMPolicy -SetId $setId -Name 'Allow notepad' -FileName 'notepad.exe' -Description 'Inactive until reviewed'
New-EPMPolicy -SetId $setId -Policy (Get-Content ./policy.json -Raw)
```

Notes:

- `Applications` must be a JSON array. A single application sent as an object returns HTTP 400 "Missing mandatory parameter - Applications".
- The API reference does not list body fields on the create page; it points to the policy definition pages.
- To find a new policy with `Get-EPMPolicy`, search by name (`-Name`) or use the returned `PolicyId`. An empty search filter does not return every policy type.
