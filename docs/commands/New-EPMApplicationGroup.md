# New-EPMApplicationGroup

Creates an application group in a set.

API: `POST /Sets/{SetId}/Policies/ApplicationGroups`. Returns HTTP 201 with the definition.

Two ways to call it:

- **File name** (default). Builds the same body as the example script: one application matched by file name.
- **FromObject**. `-Policy` is a full definition as a JSON string (sent unchanged), a hashtable, or an object (converted with arrays kept as arrays).

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Name | Group name (file name set) |
| FileName | File name to match, for example `notepad.exe` (file name set) |
| Description | Optional description (file name set) |
| PolicyType | Default 14, the application group type (file name set) |
| Policy | Full definition (FromObject set) |
| WhatIf, Confirm | Standard. ConfirmImpact is Medium |

File name body:

```json
{
  "Name": "<Name>", "PolicyType": 14, "Description": "<Description>",
  "Applications": [
    { "applicationType": 3, "displayName": "<FileName>",
      "patterns": { "FILE_NAME": { "@type": "FileName", "isEmpty": false, "compareAs": 0, "caseSensitive": false, "content": "<FileName>" } } }
  ]
}
```

Output: `psEPM.ApplicationGroupDefinition` with `Id`, `Name`, `PolicyType`, `Description`, `Applications`, `LinkedAgentPolicies`, and the added `SetId` and `ApplicationGroupId` properties.

Example:

```powershell
New-EPMApplicationGroup -SetId $setId -Name 'Editors' -FileName 'notepad.exe' -Description 'Text editors'
```

Notes:

- `Applications` must be a JSON array. One application sent as an object returns HTTP 400 "Missing mandatory parameter - Applications".
- The API fills in the other application patterns (publisher, owner, location, and so on) as empty entries and gives each application an `id`.
