# codebase-memory-mcp 接入 CodeBuddy（换机复现）

[codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)：本地代码知识图谱 MCP（tree-sitter → 本地 SQLite，158 语言，14 个 MCP 工具，零运行时依赖，单静态二进制）。官方 installer **不适配 CodeBuddy**，故二进制按官方装、MCP 配置手填。

## 关键事实

- CodeBuddy 的 MCP 配置在 `~/.codebuddy/mcp.json`（结构 `{ "mcpServers": { ... } }`，stdio 型用 `command`/`args`/`type:"stdio"`）。
- 启动方式特殊：**没有 `mcp`/`serve` 子命令，直接运行二进制本身就是 MCP stdio server** → `args` 填 `[]`。
- 数据全本地，落在 `~/.cache/codebase-memory-mcp/`，代码不出本机。
- 与 codegraph 功能重叠（都是 tree-sitter→本地图谱），**勿对同一项目双建图谱**，详见取舍段。

## 换机复现步骤

### 1. 装二进制（按官方，自行审阅脚本）

Windows（PowerShell）：
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1 -OutFile install.ps1
notepad install.ps1        # 审阅
.\install.ps1              # 可选: --ui / --skip-config / --dir=<path>
```
mac/linux：`curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash`
（也支持 npm/PyPI/Homebrew/Scoop/Winget/Chocolatey/AUR/`go install`，确切命令见官方）

### 2. 找到二进制绝对路径并验证

```powershell
Get-Command codebase-memory-mcp        # 或安装时 --dir 指定的位置
echo '{}' | & "<二进制绝对路径>"        # 应输出 JSON，说明 stdio server 正常
```

### 3. 接入 CodeBuddy MCP（手填 `~/.codebuddy/mcp.json`）

在 `mcpServers` 下加（command 换成第 2 步的实际绝对路径，启用时 `disabled` 删除或设 false）：
```json
"codebase-memory-mcp": {
  "command": "<二进制绝对路径>",
  "args": [],
  "type": "stdio"
}
```
> Windows 路径用双反斜杠转义，如 `C:\\Users\\you\\...\\codebase-memory-mcp.exe`。

### 4. 放引导 rule

把本目录的 `codebase-memory.md` 拷到 `~/.codebuddy/rules/`（让 agent 调用链/影响面/符号/架构类需求优先走它）。

### 5. 重启 CodeBuddy，索引项目

- 重启后 MCP 列表应出现 `codebase-memory-mcp`（14 个工具）。
- 首次对某项目使用前先索引：对 agent 说「Index this project」，或
  `codebase-memory-mcp cli index_repository '{"repo_path":"<绝对路径>"}'`（必须绝对路径）。

## 与 codegraph 的取舍

本仓另有 `codegraph-patches/`（同类图谱方案）。两者重叠：
- 优先用 codebase-memory-mcp（语言更全、含 LSP 级类型解析、工具更多）。
- 启用本工具后，把 codegraph 在 `~/.codebuddy/mcp.json` 设 `disabled: true`，避免双份索引。
- 一个项目同一时间只用一套。

## 兜底

- MCP 列表没出现：检查 `command` 路径、`echo '{}' | 二进制` 是否输出 JSON、是否重启。
- 工具报「not indexed / empty」：先索引（第 5 步），且 repo_path 用绝对路径。
