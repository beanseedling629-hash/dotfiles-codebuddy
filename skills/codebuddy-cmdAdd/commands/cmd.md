## Usage
`/cmdAdd:cmd [COMMAND_NAME] [DESCRIPTION]`

## Context
- Command to create: $ARGUMENTS
- Helper for creating correctly structured CodeBuddy slash commands

## Process

1. **Parse Input**: Extract command name and description from arguments
   - If name contains `:`, split into `prefix/subcommand` (e.g., `opsx:compare` → `opsx/compare.md`)
   - If no description provided, ask the user

2. **Determine Scope**: Ask user if not obvious
   - **Global** → `~/.codebuddy/commands/`
   - **Project** → `<project-root>/.codebuddy/commands/`

3. **Check for Skill Association**: 
   - If the command prefix matches an existing skill in `~/.codebuddy/skills/`, offer dual registration
   - If yes: create both IDE command file AND skill-internal command file

4. **Create Command File**:
   ```
   ---
   description: "<user-provided description>"
   argument-hint: "<inferred or asked>"
   ---
   
   <command prompt body>
   ```

5. **⚠️ CRITICAL — Directory Structure**:
   - Sub-commands MUST use subdirectories: `commands/prefix/name.md`
   - NEVER use colons in filenames: ~~`commands/prefix:name.md`~~

6. **If Skill Dual Registration**:
   - Create `~/.codebuddy/skills/<skill>/commands/<name>.md` (full command definition)
   - Create IDE entry in `~/.codebuddy/commands/<prefix>/<name>.md` (frontmatter + brief reference)
   - Update `plugin.json` and `skill.json` in the skill directory

7. **Verify**: List created files and confirm structure is correct

## Output
- Created file paths
- Registered command name (e.g., `/prefix:name`)
- Reminder to reload IDE if commands don't appear immediately
