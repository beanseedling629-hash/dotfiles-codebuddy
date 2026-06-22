# codebase-memory-mcp 使用规则

[codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) 是本地代码知识图谱 MCP（tree-sitter → 本地 SQLite 图谱，158 语言，14 个 MCP 工具）。查代码结构时优先用它，省 token、比 grep/逐文件读更准。

## 何时用它（优先于 grep / 逐文件 read）

- 查"谁调用了 X / X 调用了谁" → 调用链工具
- 改 X 前评估影响面、爆炸半径 → 影响分析工具
- 在大仓里定位符号、类型、定义 → 搜索 / 语义搜索工具
- 理解模块架构、依赖关系、跨服务调用 → 架构 / 跨服务链接工具
- 死代码检测、ADR 查询 → 对应工具

## 何时不用它（仍用 grep）

- 找纯文本 / 日志 / 注释 / 配置值的字面匹配
- 项目只有几个文件，直接 read 更快

## 使用前提

- 二进制需先安装（见 dotfiles `codebase-memory-patches/SETUP.md`），并把 `~/.codebuddy/mcp.json` 里 codebase-memory-mcp 条目的 `command` 改成实际二进制绝对路径、`disabled` 改为 `false`，重启 CodeBuddy。
- 首次对某项目使用前需先索引：对 agent 说「Index this project」，或 CLI `codebase-memory-mcp cli index_repository '{"repo_path":"<绝对路径>"}'`。
- 图谱可能过时：代码大改后重新索引。

## 与 codegraph 的取舍（重要）

本机此前已接入 codegraph（同为 tree-sitter→本地图谱→MCP）。两者功能重叠，**不要同时对同一项目各建一份图谱**，避免双份索引浪费磁盘/资源：

- 优先用 codebase-memory-mcp（语言覆盖更广、含 LSP 级类型解析、工具更全）。
- 启用 codebase-memory 后，建议把 codegraph 在 `~/.codebuddy/mcp.json` 里设 `disabled: true`（保留配置备用，不并行运行）。
- 一个项目同一时间只用一套图谱。
