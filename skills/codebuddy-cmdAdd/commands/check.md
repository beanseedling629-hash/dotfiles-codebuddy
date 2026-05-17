## Usage
`/cmdAdd:check [COMMAND_OR_SKILL_NAME]`

## Context
- Target to diagnose: $ARGUMENTS
- Troubleshoot why a command or skill isn't working as expected

## Process

1. **Scan Registration Points**:
   - Check `~/.codebuddy/commands/` (global IDE commands)
   - Check `<project>/.codebuddy/commands/` (project IDE commands)
   - Check `~/.codebuddy/skills/*/commands/` (skill-internal commands)
   - Check `~/.codebuddy/skills/*/plugin.json` (skill command registry)
   - Check `~/.codebuddy/skills/*/skill.json` (skill metadata)

2. **Run Diagnostic Checklist**:

   ### Common Pitfalls (auto-check all)
   - [ ] **Colon-in-filename bug**: Any file with `:` in its name under `commands/`?
         → Fix: rename to subdirectory structure (`prefix/name.md`)
   - [ ] **Missing Frontmatter**: IDE command files without `---` YAML block?
         → Fix: add `description` and optionally `argument-hint`
   - [ ] **Missing description**: Frontmatter exists but `description` field missing?
         → Fix: add description (required for autocomplete to show)
   - [ ] **Orphan registration**: Command in plugin.json but `.md` file doesn't exist?
         → Fix: create the missing file or remove the registry entry
   - [ ] **Unregistered command**: `.md` file exists but not in plugin.json/skill.json?
         → Fix: add to both registry files
   - [ ] **Wrong scope**: Command at global level but expected at project level (or vice versa)?
   - [ ] **File extension**: File doesn't end with `.md`?

3. **Report Results**:

## Output Format

### Status: ✅ OK / ⚠️ Issues Found

| Check | Status | Detail |
|-------|--------|--------|
| File location | ✅/❌ | ... |
| Naming convention | ✅/❌ | ... |
| Frontmatter | ✅/❌ | ... |
| Skill registration | ✅/❌ | ... |
| IDE registration | ✅/❌ | ... |

### Fixes (if issues found)
1. [specific fix action]
2. [specific fix action]

### Ask
> Apply fixes automatically? (y/n)
