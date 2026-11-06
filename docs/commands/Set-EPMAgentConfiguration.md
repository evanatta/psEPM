# Set-EPMAgentConfiguration

Updates an agent configuration.

API: `GET /Sets/{SetId}/Policies/AgentConfiguration/{AgentConfigurationId}`, then `PUT` to the same path with the bare configuration definition (no `Policy` wrapper)

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| AgentConfigurationId | Configuration ID, pipeline by property name. Alias `PolicyId`, so `Get-EPMAgentConfiguration` rows pipe in |
| Name | New name (merge) |
| Description | New description (merge). An empty string clears it |
| Policy | A full replacement definition: an object or a JSON string. A details object is unwrapped from `Policy`. `SetId`, `PolicyId`, and `AgentConfigurationId` are dropped. No read is made |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` Medium. `-WhatIf` sends nothing, including the read |

The PUT replaces the whole configuration. In merge mode the command reads the current details and takes the `Policy` definition. It changes only the fields you pass and sends every other section back unchanged, including `Executors`, `Accounts`, `AgentBehavior`, and the computer group lists, so nothing is cleared. In both modes `Id` in the body is set to the ID in the path.

Output: `psEPM.AgentConfigurationDefinition`, the policy entity the API returns, plus `SetId`, `AgentConfigurationId`, and `PolicyId`.

Examples:

```powershell
Set-EPMAgentConfiguration -SetId $setId -AgentConfigurationId $configId -Description 'Lab computers' -WhatIf
Get-EPMAgentConfiguration -SetId $setId -Name 'APITEST_' | Set-EPMAgentConfiguration -Name 'APITEST_AgentConfig2' -WhatIf
$definition = Get-EPMAgentConfiguration -SetId $setId -AgentConfigurationId $configId
Set-EPMAgentConfiguration -SetId $setId -AgentConfigurationId $configId -Policy $definition -WhatIf
```

Notes:

- `-Name`, `-Description`, or `-Policy` is required. A call with no change, or a blank name, is rejected before any request.
- The General configuration's ID is the set ID. A computer-specific configuration's ID is its endpoint ID.
- An unknown ID returns HTTP 400 `EPM000002E` on PUT, not 404. In merge mode the read fails first with HTTP 404 `EPM060001E` "Policy not found.", and no PUT is sent. Both were checked with a made-up ID on a test set in November 2026.
- `-Default` from `Get-EPMAgentConfiguration` is the product default template. Passing it to `-Policy` would replace the configuration with product defaults.
- No live update of a real configuration was run with this command.
