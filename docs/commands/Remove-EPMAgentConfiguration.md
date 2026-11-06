# Remove-EPMAgentConfiguration

Deletes computer-specific agent configurations.

API: `DELETE /Sets/{SetId}/Policies/AgentConfiguration/{AgentConfigurationId}`

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| AgentConfigurationId | One or more configuration IDs, pipeline by property name. Alias `PolicyId`, so `Get-EPMAgentConfiguration` rows pipe in |
| Name | Shown in the confirmation prompt and in the output. Pipeline by property name, alias `PolicyName`. Used only with a single ID |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` High. `-WhatIf` sends nothing |

Output: `psEPM.AgentConfigurationRemoval` with `SetId`, `AgentConfigurationId`, and `Name` (when known), one per deleted configuration.

Examples:

```powershell
Remove-EPMAgentConfiguration -SetId $setId -AgentConfigurationId $configId -WhatIf
Get-EPMAgentConfiguration -SetId $setId -Name 'APITEST_' | Remove-EPMAgentConfiguration -WhatIf
```

Notes:

- The command sends one DELETE per ID and does not retry it.
- The set's General configuration (its ID is the set ID) is refused with an error before any request. The API page describes this call as deleting a custom configuration.
- An unknown ID returns HTTP 404 `EPM060001E` "Policy not found." This was checked with a made-up ID on a test set in November 2026.
- After a successful delete (HTTP 204), the configuration is gone from the search, but `GET` by ID can still return it with HTTP 200, and a second DELETE can also return 204. Confirm a delete with `Get-EPMAgentConfiguration -SetId $setId -Name <name>`, not with a details read by ID.
- The API page says the result is a policy entity with a `location` header. The call has been seen to return 204 with no body.
- No live delete of a real configuration was run with this command.
