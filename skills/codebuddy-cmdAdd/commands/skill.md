## Usage
`/cmdAdd:skill [SKILL_NAME]`

## Context
- Skill to install or scaffold: $ARGUMENTS
- Helper for creating or installing CodeBuddy skills with correct structure

## Process

1. **Determine Action**:
   - If a URL or package name is given → install from source
   - If a plain name is given → scaffold a new skill from scratch

2. **Scaffold New Skill** (`~/.codebuddy/skills/<name>/`):

   a. Create directory structure:
   ```
   ~/.codebuddy/skills/<name>/
   ├── <name>              # Main skill prompt (no extension)
   ├── skill.json          # Lightweight metadata
   ├── commands/           # Command definitions
   │   └── (empty, user adds later via /cmdAdd:cmd)
   └── README.md           # Optional documentation
   ```

   b. Generate `skill.json`:
   ```json
   {
     "name": "<name>",
     "displayName": "<Name>",
     "description": "<ask user or infer>",
     "version": "1.0.0",
     "author": "<current user>",
     "commands": []
   }
   ```

   c. Generate main prompt file with placeholder structure

3. **Install Existing Skill** (from URL/repo):
   - Clone or download to `~/.codebuddy/skills/<name>/`
   - Verify `skill.json` exists and is valid
   - Check if commands need IDE registration

4. **IDE Command Registration** (optional):
   - Ask if user wants skill commands to also appear in IDE `/` autocomplete
   - If yes, create entries in `~/.codebuddy/commands/<prefix>/`
   - Use YAML Frontmatter format with description and argument-hint

5. **Verify**:
   - Confirm skill directory structure
   - List registered commands
   - Remind user to reload if needed

## Output
- Created/installed skill path
- Available commands list
- Next steps (add commands with `/cmdAdd:cmd`)
