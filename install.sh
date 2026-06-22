#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# dotfiles-codebuddy installer
# Copies custom CodeBuddy skills, commands, and MCP config
# to ~/.codebuddy/ with conflict detection & interactive prompt
# ============================================================

CB_DIR="$HOME/.codebuddy"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
SKIP_CONFIRM=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC} $*"; }

# --- Args ---
usage() {
  echo "Usage: $0 [--dry-run] [--yes] [--help]"
  echo "  --dry-run   Show what would be done without making changes"
  echo "  --yes       Skip confirmation prompts (overwrite all conflicts)"
  echo "  --help      Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --yes)     SKIP_CONFIRM=true; shift ;;
    --help)    usage ;;
    *)         err "Unknown argument: $1"; usage ;;
  esac
done

# --- Dep check ---
if ! command -v jq &>/dev/null; then
  err "jq is required but not installed. Install with: brew install jq"
  exit 1
fi

# --- Helper: ask yes/no ---
ask_yes() {
  local prompt="$1"
  local default="${2:-n}"  # default answer: y or n
  if $SKIP_CONFIRM; then
    return 0
  fi
  local suffix
  if [[ "$default" == "y" ]]; then
    suffix="[Y/n]"
  else
    suffix="[y/N]"
  fi
  while true; do
    echo -ne "${YELLOW}${prompt} ${suffix}${NC} "
    read -r answer
    answer="${answer:-$default}"
    case "$answer" in
      y|Y|yes) return 0 ;;
      n|N|no)  return 1 ;;
      *)       echo "Please answer y or n." ;;
    esac
  done
}

# --- Helper: copy with conflict detection ---
# Returns: 0=installed, 1=skipped, 2=identical
install_file() {
  local src="$1"
  local dest="$2"
  local label="${3:-$(basename "$dest")}"

  if [[ ! -f "$src" ]]; then
    err "Source file missing: $src"
    return 1
  fi

  if [[ ! -f "$dest" ]]; then
    # New file
    if $DRY_RUN; then
      info "[DRY-RUN] Would create: $dest"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      ok "Created: $label"
    fi
    return 0
  fi

  if diff -q "$src" "$dest" &>/dev/null; then
    # Identical
    return 2
  fi

  # Conflict
  warn "Conflict: $label already exists and differs"
  if ask_yes "  Overwrite $dest?"; then
    if $DRY_RUN; then
      info "[DRY-RUN] Would overwrite: $dest"
    else
      cp "$src" "$dest"
      ok "Overwritten: $label"
    fi
    return 0
  else
    info "Skipped: $label"
    return 1
  fi
}

# --- Helper: install directory recursively ---
install_dir() {
  local src_dir="$1"
  local dest_dir="$2"
  local prefix="${3:-}"

  local created=0 skipped=0 identical=0

  while IFS= read -r -d '' src_file; do
    local rel="${src_file#$src_dir}"
    local dest_file="${dest_dir}${rel}"
    local label="${prefix}${rel}"

    install_file "$src_file" "$dest_file" "$label"
    case $? in
      0) ((created++)) ;;
      1) ((skipped++)) ;;
      2) ((identical++)) ;;
    esac
  done < <(find "$src_dir" -type f -print0)

  echo "    Created: $created, Skipped: $skipped, Identical: $identical"
}

# ============================================================
# MAIN
# ============================================================

echo ""
echo "=========================================="
echo "  dotfiles-codebuddy installer"
echo "=========================================="
echo ""

if $DRY_RUN; then
  warn "DRY-RUN MODE — no changes will be made"
  echo ""
fi

# --- 1. Install codebuddy-cmdAdd skill ---
echo "--- Step 1/7: codebuddy-cmdAdd skill ---"
install_dir "$SCRIPT_DIR/skills/codebuddy-cmdAdd" "$CB_DIR/skills/codebuddy-cmdAdd" "skills/codebuddy-cmdAdd"
echo ""

# --- 2. Install global IDE commands (cmdAdd) ---
echo "--- Step 2/7: Global commands/cmdAdd/ ---"
install_dir "$SCRIPT_DIR/commands/cmdAdd" "$CB_DIR/commands/cmdAdd" "commands/cmdAdd"
echo ""

# --- 3. Install global IDE commands (opsx) ---
echo "--- Step 3/7: Global commands/opsx/ ---"
install_dir "$SCRIPT_DIR/commands/opsx" "$CB_DIR/commands/opsx" "commands/opsx"
echo ""

# --- 4. OpenSpec patches ---
echo "--- Step 4/7: OpenSpec custom commands patch ---"
OPENSPEC_DIR="$CB_DIR/skills/openspec"

if [[ ! -d "$OPENSPEC_DIR" ]]; then
  warn "OpenSpec skill not found at $OPENSPEC_DIR"
  warn "Skipping patch. Install OpenSpec first, then re-run this script."
else
  # 4a. Copy command files
  patch_created=0
  for cmd_file in "$SCRIPT_DIR/openspec-patches/commands/"*.md; do
    [[ -f "$cmd_file" ]] || continue
    cmd_name="$(basename "$cmd_file")"
    dest="$OPENSPEC_DIR/commands/$cmd_name"
    install_file "$cmd_file" "$dest" "openspec/commands/$cmd_name"
    case $? in
      0) ((patch_created++)) ;;
    esac
  done

  # 4b. Patch skill.json — append new commands
  skill_json="$OPENSPEC_DIR/skill.json"
  if [[ -f "$skill_json" ]] && [[ -f "$SCRIPT_DIR/openspec-patches/skill.json.append.json" ]]; then
    append_data=$(cat "$SCRIPT_DIR/openspec-patches/skill.json.append.json")
    existing_cmds=$(jq -r '.commands[]' "$skill_json" 2>/dev/null || echo "")

    new_entries=0
    for entry in $(echo "$append_data" | jq -r '.[]'); do
      cmd_name=$(echo "$entry" | sed 's/ .*//')  # extract /opsx:compare
      if echo "$existing_cmds" | grep -qF "$cmd_name"; then
        info "skill.json: $cmd_name already registered, skipping"
      else
        if $DRY_RUN; then
          info "[DRY-RUN] Would append to skill.json: $entry"
        else
          jq --argjson entry "$entry" '.commands += [$entry]' "$skill_json" > "${skill_json}.tmp" && mv "${skill_json}.tmp" "$skill_json"
          ok "Appended to skill.json: $cmd_name"
        fi
        ((new_entries++))
      fi
    done
    [[ $new_entries -eq 0 ]] && info "skill.json: no new entries to append"
  fi

  # 4c. Patch plugin.json — append new command objects
  plugin_json="$OPENSPEC_DIR/plugin.json"
  if [[ -f "$plugin_json" ]] && [[ -f "$SCRIPT_DIR/openspec-patches/plugin.json.append.json" ]]; then
    append_data=$(cat "$SCRIPT_DIR/openspec-patches/plugin.json.append.json")
    existing_names=$(jq -r '.commands[].name' "$plugin_json" 2>/dev/null || echo "")

    new_entries=0
    for row in $(echo "$append_data" | jq -c '.[]'); do
      cmd_name=$(echo "$row" | jq -r '.name')
      if echo "$existing_names" | grep -qF "$cmd_name"; then
        info "plugin.json: $cmd_name already registered, skipping"
      else
        if $DRY_RUN; then
          info "[DRY-RUN] Would append to plugin.json: $cmd_name"
        else
          jq --argjson row "$row" '.commands += [$row]' "$plugin_json" > "${plugin_json}.tmp" && mv "${plugin_json}.tmp" "$plugin_json"
          ok "Appended to plugin.json: $cmd_name"
        fi
        ((new_entries++))
      fi
    done
    [[ $new_entries -eq 0 ]] && info "plugin.json: no new entries to append"
  fi
fi
echo ""

# --- 5. MCP config merge ---
echo "--- Step 5/7: MCP configuration ---"
MCP_FILE="$CB_DIR/mcp.json"
MCP_EXAMPLE="$SCRIPT_DIR/mcp.json.example"

if [[ ! -f "$MCP_FILE" ]]; then
  # No existing mcp.json — copy template
  if ask_yes "No ~/.codebuddy/mcp.json found. Create from template? (You'll need to edit __PROJECT_DIR__)"; then
    if $DRY_RUN; then
      info "[DRY-RUN] Would create: $MCP_FILE from template"
    else
      cp "$MCP_EXAMPLE" "$MCP_FILE"
      ok "Created: $MCP_FILE (edit __PROJECT_DIR__ placeholders!)"
    fi
  else
    info "Skipped: MCP configuration"
  fi
else
  # Merge — only add missing keys
  example_servers=$(jq -r '.mcpServers | keys[]' "$MCP_EXAMPLE" 2>/dev/null)
  existing_servers=$(jq -r '.mcpServers | keys[]' "$MCP_FILE" 2>/dev/null)
  merged=0

  for server in $example_servers; do
    if echo "$existing_servers" | grep -qF "$server"; then
      info "mcp.json: '$server' already exists, skipping"
    else
      server_config=$(jq --arg name "$server" '.mcpServers[$name]' "$MCP_EXAMPLE")
      if ask_yes "  Add '$server' to mcp.json?"; then
        if $DRY_RUN; then
          info "[DRY-RUN] Would add '$server' to mcp.json"
        else
          jq --arg name "$server" --argjson config "$server_config" \
            '.mcpServers[$name] = $config' "$MCP_FILE" > "${MCP_FILE}.tmp" && mv "${MCP_FILE}.tmp" "$MCP_FILE"
          ok "Added '$server' to mcp.json"
        fi
        ((merged++))
      fi
    fi
  done

  [[ $merged -eq 0 ]] && info "mcp.json: no new servers to add"

  # Warn about placeholders
  if grep -q '__PROJECT_DIR__' "$MCP_FILE" 2>/dev/null; then
    warn "mcp.json contains __PROJECT_DIR__ placeholder — edit it to point to your project!"
  fi
fi
echo ""

# --- 6. codegraph (CodeBuddy target) ---
# codegraph 不走 ~/.codebuddy/mcp.json，需 npm 构建 + 自身写入 globalStorage。
# 此步仅做指引/检测，不复制文件（详见 codegraph-patches/SETUP.md）。
echo "--- Step 6/7: codegraph (CodeBuddy target) ---"
if command -v codegraph &>/dev/null; then
  ok "codegraph command found: $(command -v codegraph)"
  info "Run to (re)write CodeBuddy MCP config: codegraph install --target=codebuddy --location=global -y"
else
  warn "codegraph not installed. To set up (one-time):"
  echo "    1. git clone https://github.com/colbymchenry/codegraph.git && cd codegraph"
  echo "    2. cp $SCRIPT_DIR/codegraph-patches/targets/codebuddy.ts src/installer/targets/"
  echo "       (and manually add 'codebuddy' to types.ts TargetId + register in registry.ts)"
  echo "    3. npm install && npm run build && npm link"
  echo "    4. codegraph install --target=codebuddy --location=global -y"
  echo "    5. cd <your-project> && codegraph init"
  info "Full guide: codegraph-patches/SETUP.md"
fi
warn "NOTE: codegraph writes CodeBuddy's globalStorage settings, NOT ~/.codebuddy/mcp.json."
echo ""

# --- 7. ponytail rule/commands + codebase-memory-mcp guidance ---
echo "--- Step 7/7: ponytail (rule + commands) & codebase-memory-mcp ---"
# 7a. ponytail：纯规则模式，拷 rule + 命令到 ~/.codebuddy/（低耦合追加）
if [[ -f "$SCRIPT_DIR/ponytail/rules/ponytail.md" ]]; then
  install_file "$SCRIPT_DIR/ponytail/rules/ponytail.md" "$CB_DIR/rules/ponytail.md" "rules/ponytail.md"
fi
if [[ -d "$SCRIPT_DIR/ponytail/commands" ]]; then
  install_dir "$SCRIPT_DIR/ponytail/commands" "$CB_DIR/commands" "commands"
fi

# 7b. codebase-memory-mcp：二进制需官方装 + 手填 mcp.json，此处仅拷引导 rule + 打印指引
if [[ -f "$SCRIPT_DIR/codebase-memory-patches/codebase-memory.md" ]]; then
  install_file "$SCRIPT_DIR/codebase-memory-patches/codebase-memory.md" "$CB_DIR/rules/codebase-memory.md" "rules/codebase-memory.md"
fi
if command -v codebase-memory-mcp &>/dev/null; then
  ok "codebase-memory-mcp found: $(command -v codebase-memory-mcp)"
  info "Add to ~/.codebuddy/mcp.json: { command: <abs path>, args: [], type: stdio }; then index a repo."
else
  warn "codebase-memory-mcp not installed. To set up (one-time):"
  echo "    1. Install binary (Windows): download & run install.ps1 from DeusData/codebase-memory-mcp"
  echo "       (mac/linux: curl -fsSL .../install.sh | bash) — review the script first"
  echo "    2. Find binary path; verify: echo '{}' | <binary> should print JSON"
  echo "    3. Add to ~/.codebuddy/mcp.json mcpServers: { \"codebase-memory-mcp\": { \"command\": \"<abs path>\", \"args\": [], \"type\": \"stdio\" } }"
  echo "    4. Restart CodeBuddy; index a project: codebase-memory-mcp cli index_repository '{\"repo_path\":\"<abs>\"}'"
  info "Full guide: codebase-memory-patches/SETUP.md"
fi
warn "NOTE: codebase-memory-mcp overlaps with codegraph — enable only one per project to avoid double-indexing."
echo ""

# --- Summary ---
echo "=========================================="
echo "  Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. If you installed MCP config, edit ~/.codebuddy/mcp.json and replace __PROJECT_DIR__"
echo "  2. If you have project-level .codebuddy/commands/opsx/ — remove it (now in user-level)"
echo "  3. Restart CodeBuddy IDE to pick up changes"
echo ""
