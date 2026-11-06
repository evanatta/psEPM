## What changed

## Tests run

- [ ] `Invoke-Pester ./Tests`
- [ ] `Invoke-ScriptAnalyzer -Path ./psEPM -Recurse -Settings ./PSScriptAnalyzerSettings.psd1` reports no findings
- [ ] Live check against a test set, if the change calls the API (describe it without IDs or names)

## Checklist

- [ ] `CHANGELOG.md` updated under `Unreleased`
- [ ] Help in `docs/commands` added or updated
- [ ] New public commands added to `FunctionsToExport` and the README command table
- [ ] No comments in code files; Windows PowerShell 5.1 compatible
- [ ] No tokens, secrets, or tenant IDs in the change
