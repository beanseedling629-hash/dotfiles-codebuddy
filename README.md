# dotfiles-codebuddy

个人 CodeBuddy 配置仓库，包含自创 skill、自定义命令补丁和 MCP 配置模板。

## 组件清单

| 组件 | 类型 | 作用 | 需额外配置/授权 |
|------|------|------|----------------|
| **codebuddy-cmdAdd** | Skill | 命令/技能安装助手，固化子目录命名、双重注册等踩坑经验 | ❌ 无 |
| **/cmdAdd:cmd** | 斜杠命令 | 创建新的 slash command（自动处理子目录结构和双重注册） | ❌ 无 |
| **/cmdAdd:skill** | 斜杠命令 | 安装或脚手架新 skill | ❌ 无 |
| **/cmdAdd:check** | 斜杠命令 | 诊断命令/技能注册问题（冒号文件名、缺失 frontmatter 等） | ❌ 无 |
| **/opsx:compare** | 斜杠命令 | 技术/体验/交互方案并列对比，输出精简对比表格+推荐 | ❌ 无（依赖 openspec skill） |
| **/opsx:harness** | 斜杠命令 | 为功能特性生成边界情况和测试场景清单 | ❌ 无（依赖 openspec skill） |
| **/opsx:explore-brief** | 斜杠命令 | 精简版探索，~60% 更少输出 | ❌ 无（依赖 openspec skill） |
| **context7** | MCP Server | 提供最新库文档查询（如查询 React/Vue 等最新 API） | ❌ 无（公开 URL） |
| **code-review-graph** | MCP Server | 代码知识图谱，支持依赖分析、影响范围评估、语义搜索 | ⚠️ 需配置项目路径 |

## 各组件详细说明

### codebuddy-cmdAdd Skill

自创的 CodeBuddy 命令/技能管理工具，包含 3 个子命令：

- `/cmdAdd:cmd [name] [desc]` — 创建新命令，自动处理：
  - 子命令用**子目录**而非冒号文件名（`opsx/compare.md` → `/opsx:compare`）
  - 双重注册（skill 内 + IDE 补全）
  - YAML Frontmatter 生成

- `/cmdAdd:skill [name]` — 脚手架新 skill：
  - 自动创建目录结构（skill.json、commands/、主 prompt）
  - 注册到 plugin.json 和 skill.json

- `/cmdAdd:check [name]` — 诊断注册问题：
  - 检测冒号文件名
  - 检测缺失 Frontmatter
  - 检测孤立注册（skill.json 有但文件不存在等）

### OpenSpec 自定义命令补丁

为 [OpenSpec](https://github.com/Fission-AI/OpenSpec) skill 新增 3 个命令，优化 plan 模式下 token 消耗：

| 命令 | 用途 | 输出上限 |
|------|------|---------|
| `/opsx:compare` | 多方案对比评估 | ~200 行 |
| `/opsx:harness` | 测试场景/边界情况生成 | ~150 行 |
| `/opsx:explore-brief` | 精简探索（vs explore 的 100+ 行） | ~100 行 |

> **前提**：需先安装 OpenSpec skill。这些命令是增量补丁，安装脚本会自动合并到 openspec 的 skill.json/plugin.json。

### MCP 配置

**context7**（远程 MCP）：
- 提供实时库文档查询，避免 AI 使用过时的 API
- 公开 URL，无需授权
- 适用场景：查询 React 19 新 API、Next.js 15 路由变化等

**code-review-graph**（本地 MCP）：
- 构建代码知识图谱，支持依赖追踪、影响范围评估
- 需要 Python 3.10+ 和 `code_review_graph` 包
- ⚠️ 需配置 `cwd` 为你的项目路径（安装后编辑 `~/.codebuddy/mcp.json`）

## 安装方式

### 方式一：安装脚本（推荐）

```bash
# 克隆仓库
git clone https://github.com/beanseedling629-hash/dotfiles-codebuddy.git
cd dotfiles-codebuddy

# 运行安装（交互式，会检测冲突并询问）
./install.sh

# 或跳过确认（覆盖所有冲突）
./install.sh --yes

# 或预览模式（不做任何修改）
./install.sh --dry-run
```

安装脚本会：
1. ✅ 检测已有文件冲突，逐个询问是否覆盖
2. ✅ 自动合并 openspec 补丁（用 jq 追加命令到 skill.json/plugin.json）
3. ✅ 自动合并 MCP 配置（保留已有条目，只追加新的）
4. ✅ 检测重复注册（已存在的命令/skip）

**依赖**：`jq`（`brew install jq`）

### 方式二：让 CodeBuddy 安装

在 CodeBuddy 对话中粘贴以下 prompt：

```
请帮我安装 CodeBuddy dotfiles 配置：

1. 先 clone 仓库到 ~/aiProject/dotfiles-codebuddy：
   git clone https://github.com/beanseedling629-hash/dotfiles-codebuddy.git ~/aiProject/dotfiles-codebuddy

2. 运行安装脚本：
   bash ~/aiProject/dotfiles-codebuddy/install.sh

3. 安装完成后：
   - 检查 ~/.codebuddy/mcp.json 中 code-review-graph 的 cwd 是否正确
   - 如果有 __PROJECT_DIR__ 占位符，替换为实际项目路径
   - 如果项目级 .codebuddy/commands/opsx/ 目录存在，删除它（已迁移到用户层）

安装前先检测下当前已有的 skills、commands、mcp 配置，有冲突的问我要不要覆盖。
```

### 方式三：手动安装

```bash
# 1. codebuddy-cmdAdd skill
cp -r skills/codebuddy-cmdAdd ~/.codebuddy/skills/

# 2. 全局命令
cp -r commands/cmdAdd ~/.codebuddy/commands/
cp -r commands/opsx ~/.codebuddy/commands/

# 3. OpenSpec 补丁（需先安装 openspec）
cp openspec-patches/commands/*.md ~/.codebuddy/skills/openspec/commands/
# 然后手动编辑 skill.json 和 plugin.json，追加 append.json 中的条目

# 4. MCP 配置
# 手动合并 mcp.json.example 到 ~/.codebuddy/mcp.json
```

## 安装后检查

```bash
# 验证 skill
ls ~/.codebuddy/skills/codebuddy-cmdAdd/

# 验证全局命令
ls ~/.codebuddy/commands/cmdAdd/
ls ~/.codebuddy/commands/opsx/

# 验证 openspec 补丁
grep 'compare\|harness\|explore-brief' ~/.codebuddy/skills/openspec/skill.json

# 验证 MCP
cat ~/.codebuddy/mcp.json
```

## 目录结构

```
dotfiles-codebuddy/
├── README.md                      # 本文件
├── install.sh                     # 安装脚本
├── mcp.json.example               # MCP 配置模板（脱敏）
├── skills/
│   └── codebuddy-cmdAdd/          # 自创 skill
│       ├── skill.json
│       ├── codebuddy-cmdAdd       # 主 prompt
│       └── commands/
│           ├── cmd.md
│           ├── skill.md
│           └── check.md
├── openspec-patches/              # OpenSpec 自定义命令增量补丁
│   ├── commands/
│   │   ├── compare.md
│   │   ├── harness.md
│   │   └── explore-brief.md
│   ├── skill.json.append.json     # 需追加到 skill.json 的条目
│   └── plugin.json.append.json    # 需追加到 plugin.json 的条目
└── commands/                      # 全局 IDE 补全命令
    ├── cmdAdd/
    │   ├── cmd.md                 → /cmdAdd:cmd
    │   ├── skill.md               → /cmdAdd:skill
    │   └── check.md               → /cmdAdd:check
    └── opsx/
        ├── compare.md             → /opsx:compare
        ├── harness.md             → /opsx:harness
        └── explore-brief.md       → /opsx:explore-brief
```
