# ConvertTo-EPMFilter

Builds an EPM filter string from a property, an operator, and one or more values. Several clauses are joined with `AND`.

## Syntax

```
ConvertTo-EPMFilter [-Property] <string> [-Operator] <string> [-Value] <object[]>
ConvertTo-EPMFilter -InputObject <object[]>
```

## Parameters

| Name | Description |
| --- | --- |
| Property | Field name, for example `name`, `PolicyName`, `arrivalTime`, or `features.name`. Letters, digits, and `_`, with `.` between parts |
| Operator | `EQ`, `NE`, `CONTAINS`, `NOTCONTAINS`, `STARTSWITH`, `ENDSWITH`, `IN`, `NOTIN`, `GT`, `GE`, `LT`, `LE` |
| Value | The value. `IN` and `NOTIN` take one or more values; the other operators take exactly one |
| InputObject | Clauses as hashtables or objects with `Property`, `Operator`, and `Value`, from the pipeline or as an array. Joined with `AND` |

Output: one string.

## Value formatting

| Value | Written as | Example |
| --- | --- | --- |
| String with `EQ`, `NE`, `CONTAINS`, `NOTCONTAINS`, `STARTSWITH`, `ENDSWITH`, `GT`, `GE`, `LT`, `LE` | Double quoted | `name EQ "APITEST-PC"` |
| Strings with `IN`, `NOTIN` | Comma separated, not one quoted string. A value that contains a space, comma, or parenthesis is quoted on its own | `eventType IN Launch,Block`, `computerName IN "PC 1",PC2` |
| `[datetime]` | UTC ISO 8601, not quoted | `arrivalTime GE 2026-01-01T00:00:00Z` |
| Number | Invariant culture, not quoted | `membersCount GT 5` |
| `[bool]` | `true` or `false`, not quoted | `IsActive EQ true` |

## Examples

```powershell
ConvertTo-EPMFilter -Property name -Operator CONTAINS -Value 'APITEST'
ConvertTo-EPMFilter eventType IN 'Launch', 'Block'
$filter = @(
    @{ Property = 'arrivalTime'; Operator = 'GE'; Value = (Get-Date).AddDays(-7) }
    @{ Property = 'eventType'; Operator = 'IN'; Value = 'ElevationRequest', 'Block' }
) | ConvertTo-EPMFilter
Get-EPMEvent -SetId $setId -Filter $filter
Get-EPMEndpoint -SetId $setId -Filter (ConvertTo-EPMFilter name CONTAINS 'APITEST')
```

## Notes

- A value that contains a double quote, or ends with a backslash, is rejected. Values are never escaped, so a value cannot close its quotes and add another clause. A backslash elsewhere, as in `DOMAIN\user`, is allowed.
- An empty or blank property or value, a null value, no clauses, an unsupported operator, or several values for a single-value operator is rejected with an error.
- The operators are the ones on the EPM query language page. `BETWEEN`, `IS NULL`, `IS NOTNULL`, `OR`, and parentheses are not built. For those, write the filter string by hand and pass it to `-Filter`.
- A numeric string such as `'250030060000'` stays a quoted string. Pass a number to write it unquoted.
- Field names and values are case sensitive. Operators are not.
- Each field supports only some operators, listed on its API page. For example, aggregated events accept `eventType IN` but return HTTP 400 for `eventType EQ`.
- In November 2026, endpoint searches accepted `platform IN`, `name CONTAINS`, and `connectionStatus EQ`, policy searches accepted `PolicyName CONTAINS` and `IsActive EQ false`, and event searches accepted `arrivalTime GE` with `eventType IN`, all built by this command.
