# New-EPMAgentConfiguration

Creates a computer-specific agent configuration in a set.

API: `POST /Sets/{SetId}/Policies/AgentConfiguration` with the bare configuration definition (no `Policy` wrapper)

| Parameter | Description |
| --- | --- |
| SetId | Set ID, pipeline by property name |
| Name | Name of the new configuration |
| EndpointId | ID (GUID) of an existing computer in the same set. Sent as `Executors: [{"Id": "<EndpointId>", "IsIncluded": true, "ExecutorType": 1}]` |
| Description | Description of the new configuration. If omitted, the source's description is kept |
| SourceAgentConfigurationId | Configuration to copy settings from. Default: the set's General configuration (its ID is the set ID) |
| Policy | A full definition instead of the parameters above: an object or a JSON string. A `Get-EPMAgentConfiguration` details object is unwrapped from `Policy`. `SetId`, `PolicyId`, and `AgentConfigurationId` are dropped |
| WhatIf, Confirm | Standard ShouldProcess switches, `ConfirmImpact` Medium. `-WhatIf` sends nothing, including the source read |

With `-Name` and `-EndpointId`, the command follows the create flow from the API page. It reads the source configuration's details and takes its `Policy` definition. It then sets `Id` to `00000000-0000-0000-0000-000000000000`, `Name`, `Description` (if given), `IsAppliedToAllComputers` to `false`, and `Executors` to the one computer, and posts the result. With `-Policy`, the definition is sent as given, except that `Id` is always set to `00000000-0000-0000-0000-000000000000`.

Output: `psEPM.AgentConfigurationDefinition`, the policy entity the API returns, plus `SetId`, `AgentConfigurationId`, and `PolicyId`. If the API returns the details wrapper instead, the type is `psEPM.AgentConfigurationDetail`.

Examples:

```powershell
New-EPMAgentConfiguration -SetId $setId -Name 'APITEST_AgentConfig' -EndpointId $endpointId -WhatIf
New-EPMAgentConfiguration -SetId $setId -Name 'APITEST_AgentConfig' -EndpointId $endpointId -SourceAgentConfigurationId $sourceId -Description 'Lab' -WhatIf
$definition = Get-EPMAgentConfiguration -SetId $setId -AgentConfigurationId $setId
$definition.Policy.Name = 'APITEST_AgentConfig'
$definition.Policy.IsAppliedToAllComputers = $false
$definition.Policy.Executors = @(@{ Id = $endpointId; IsIncluded = $true; ExecutorType = 1 })
New-EPMAgentConfiguration -SetId $setId -Policy $definition -WhatIf
```

Notes:

- A create needs a real computer in the same set. The API page says nothing about targets. These were tested and rejected with HTTP 400:
  - no target ("at least one computer must be specified");
  - an Entra ID computer group;
  - an unknown computer ID ("does not exist");
  - an endpoint group (`ExecutorType` 0, "is not SINGLE type").
- The new configuration's ID is the endpoint ID, so a computer can have only one computer-specific configuration. `-EndpointId` takes one computer for that reason.
- Start from the set's General configuration details, not from `Get-EPMAgentConfiguration -Default`. `-Default` returns the product default template, not the set's current settings.
- The API page says the result is a policy entity, with the policy ID in the `location` header.
- Search rows report `PolicyType` 45. Details report 44 for the same configuration.
- No live create was run with this command. The only test set had no computers, and sets with computers were not written to. `-WhatIf` was run against the test set and sent nothing.
