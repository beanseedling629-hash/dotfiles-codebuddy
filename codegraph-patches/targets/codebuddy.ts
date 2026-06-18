/**
 * CodeBuddy target.
 *
 *   - Writes an MCP-server entry to CodeBuddy's user-level MCP settings
 *     file. Same `{mcpServers: {...}}` shape as Claude / Cursor.
 *   - GLOBAL ONLY. CodeBuddy keeps its MCP configuration in a fixed
 *     user-level `globalStorage` file; there is no stable project-local
 *     `.codebuddy/mcp.json` convention to write to. So `local` is
 *     unsupported and `supportsLocation('local')` returns false.
 *
 * ## Config file location
 *
 * On the observed CodeBuddy (CN) build the MCP settings live at:
 *
 *   <home>/AppData/Roaming/CodeBuddy CN/User/globalStorage/
 *     tencent.planning-genie/settings/codebuddy_mcp_settings.json
 *
 * Two fragile bits we guard against:
 *   - The path contains spaces ("CodeBuddy CN") — we always build it
 *     with `path.join`, never by hand.
 *   - The `tencent.planning-genie` plugin sub-directory may vary by
 *     CodeBuddy version / installed plugins. If the parent settings
 *     directory isn't present at install time we still write to the
 *     expected path (creating dirs) but surface a note asking the user
 *     to confirm the location for their CodeBuddy build, rather than
 *     failing silently.
 *
 * ## Why we hardcode `--path` for CodeBuddy
 *
 * Mirrors the Cursor rationale: an MCP server spawned by the editor may
 * not run with `cwd = workspace root`, so the codegraph server's
 * `process.cwd()` fallback can miss the workspace's `.codegraph/` and
 * report "not initialized". We inject `--path ${workspaceFolder}` so the
 * spawned server resolves the right project. If a given CodeBuddy build
 * does NOT expand `${workspaceFolder}`, fall back to an absolute project
 * path (see README / install notes).
 *
 * No permissions concept — CodeBuddy has no installer-populated
 * auto-allow list. `autoAllow` is silently ignored.
 */

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import {
  AgentTarget,
  DetectionResult,
  InstallOptions,
  Location,
  WriteResult,
} from './types';
import {
  getMcpServerConfig,
  jsonDeepEqual,
  readJsonFile,
  writeJsonFile,
} from './shared';

/**
 * CodeBuddy plugin sub-directory under `globalStorage` that owns the
 * MCP settings file. Centralized so the (version-fragile) value lives
 * in exactly one place.
 */
const CODEBUDDY_PLUGIN_DIR = 'tencent.planning-genie';
const CODEBUDDY_SETTINGS_FILE = 'codebuddy_mcp_settings.json';

/**
 * Absolute path to CodeBuddy's MCP settings file. CodeBuddy is
 * global-only, so `loc` is accepted for signature symmetry but the
 * result does not depend on it.
 */
function mcpJsonPath(_loc: Location): string {
  return path.join(
    os.homedir(),
    'AppData',
    'Roaming',
    'CodeBuddy CN',
    'User',
    'globalStorage',
    CODEBUDDY_PLUGIN_DIR,
    'settings',
    CODEBUDDY_SETTINGS_FILE,
  );
}

/** The `globalStorage` dir — used as the "is CodeBuddy installed" probe. */
function globalStorageDir(): string {
  return path.join(
    os.homedir(),
    'AppData',
    'Roaming',
    'CodeBuddy CN',
    'User',
    'globalStorage',
  );
}

class CodeBuddyTarget implements AgentTarget {
  readonly id = 'codebuddy' as const;
  readonly displayName = 'CodeBuddy';
  readonly docsUrl = 'https://github.com/colbymchenry/codegraph/issues/164';

  supportsLocation(loc: Location): boolean {
    // Global only — CodeBuddy has no project-local MCP config surface.
    return loc === 'global';
  }

  detect(loc: Location): DetectionResult {
    const mcpPath = mcpJsonPath(loc);
    const config = readJsonFile(mcpPath);
    const alreadyConfigured = !!config.mcpServers?.codegraph;
    // "Installed" heuristic: does the CodeBuddy globalStorage dir exist?
    const installed = fs.existsSync(globalStorageDir());
    return { installed, alreadyConfigured, configPath: mcpPath };
  }

  install(loc: Location, _opts: InstallOptions): WriteResult {
    const files: WriteResult['files'] = [];
    files.push(writeMcpEntry(loc));

    const notes = ['Restart CodeBuddy for MCP changes to take effect.'];

    // Path-fragility self-check: if the expected settings directory
    // wasn't there before we wrote, the plugin sub-dir name may differ
    // for this CodeBuddy build — tell the user instead of failing quietly.
    if (!fs.existsSync(globalStorageDir())) {
      notes.push(
        `Could not find CodeBuddy globalStorage at ${globalStorageDir()}. ` +
        `If MCP doesn't load, confirm your CodeBuddy MCP settings path and re-run.`,
      );
    }
    notes.push(
      "If tools report 'not initialized', your CodeBuddy build may not expand " +
      '${workspaceFolder}; replace it in the config with the absolute project path.',
    );

    return { files, notes };
  }

  uninstall(loc: Location): WriteResult {
    const files: WriteResult['files'] = [];
    const mcpPath = mcpJsonPath(loc);
    const config = readJsonFile(mcpPath);
    if (config.mcpServers?.codegraph) {
      delete config.mcpServers.codegraph;
      if (Object.keys(config.mcpServers).length === 0) {
        delete config.mcpServers;
      }
      writeJsonFile(mcpPath, config);
      files.push({ path: mcpPath, action: 'removed' });
    } else {
      files.push({ path: mcpPath, action: 'not-found' });
    }
    return { files };
  }

  printConfig(loc: Location): string {
    const target = mcpJsonPath(loc);
    const snippet = JSON.stringify(
      { mcpServers: { codegraph: buildCodeBuddyMcpConfig() } },
      null,
      2,
    );
    return `# Add to ${target}\n\n${snippet}\n`;
  }

  describePaths(loc: Location): string[] {
    return [mcpJsonPath(loc)];
  }
}

/**
 * Build the codegraph MCP-server config for CodeBuddy. Inherits the
 * shared shape ({type, command, args}) and appends `--path
 * ${workspaceFolder}` so the spawned MCP server resolves the workspace
 * regardless of CodeBuddy's launch cwd. See file header for rationale.
 */
function buildCodeBuddyMcpConfig(): { type: string; command: string; args: string[] } {
  const base = getMcpServerConfig();
  return { ...base, args: [...base.args, '--path', '${workspaceFolder}'] };
}

function writeMcpEntry(loc: Location): WriteResult['files'][number] {
  const file = mcpJsonPath(loc);
  const existing = readJsonFile(file);
  const before = existing.mcpServers?.codegraph;
  const after = buildCodeBuddyMcpConfig();

  if (jsonDeepEqual(before, after)) {
    return { path: file, action: 'unchanged' };
  }
  const action: 'created' | 'updated' = fs.existsSync(file) ? 'updated' : 'created';
  if (!existing.mcpServers) existing.mcpServers = {};
  existing.mcpServers.codegraph = after;
  writeJsonFile(file, existing);
  return { path: file, action };
}

export const codebuddyTarget: AgentTarget = new CodeBuddyTarget();
