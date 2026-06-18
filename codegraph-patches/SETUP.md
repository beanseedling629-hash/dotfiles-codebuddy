# codegraph + CodeBuddy target 复现说明

为 [codegraph](https://github.com/colbymchenry/codegraph) 增加一流安装目标 `--target=codebuddy`，
让 `codegraph install --target=codebuddy` 能一键把 MCP 配置写进 CodeBuddy。

> 背景：官方 issue [#164](https://github.com/colbymchenry/codegraph/issues/164) 把 CodeBuddy 支持
> Closed as not planned；#649 说明 CodeBuddy 目前只在「待提升为一键 target」名单。本补丁自己补上了这个 target。

## 关键事实（务必先读）

- CodeBuddy 真正读取的 MCP 配置文件是**用户级 globalStorage**：
  ```
  C:\Users\<你>\AppData\Roaming\CodeBuddy CN\User\globalStorage\tencent.planning-genie\settings\codebuddy_mcp_settings.json
  ```
  **不是** `~/.codebuddy/mcp.json`（dotfiles 里 code-review-graph 走的那套是另一个体系）。
- 所以 codegraph 的安装**靠 `codegraph install --target=codebuddy` 自己写 globalStorage**，
  本仓 `mcp.json.example` 里的 codegraph 条目仅作「参考片段/手动兜底」，照它手填进 `~/.codebuddy/mcp.json` **不会生效**。
- `globalStorage\tencent.planning-genie` 这个插件子目录名可能随 CodeBuddy 版本变化；找不到时按提示确认实际路径。

## 本补丁改动（共 3 个文件，全在 `src/installer/targets/`）

| 文件 | 改动 |
|------|------|
| `codebuddy.ts` | **新增**，完整实现 `CodeBuddyTarget`（见本目录 `targets/codebuddy.ts`） |
| `types.ts` | `TargetId` 联合类型**末尾加** `\| 'codebuddy'` |
| `registry.ts` | 顶部 `import { codebuddyTarget } from './codebuddy';`，`ALL_TARGETS` 数组**末尾追加** `codebuddyTarget,` |

> 本目录 `targets/` 下存的是改好的完整文件副本。换机时：`codebuddy.ts` 直接拷入；
> `types.ts` / `registry.ts` 官方会迭代，**优先手动加上面那两处**，副本仅作对照，整文件覆盖易冲突。

## 换机复现步骤

```bash
# 1. clone 官方源码
git clone https://github.com/colbymchenry/codegraph.git
cd codegraph

# 2. 合入本补丁（codebuddy.ts 直接拷；types/registry 优先手动改那两行）
#    源： <dotfiles>/codegraph-patches/targets/*.ts
cp <dotfiles>/codegraph-patches/targets/codebuddy.ts src/installer/targets/
#    手动编辑 src/installer/targets/types.ts   —— TargetId 末尾加 'codebuddy'
#    手动编辑 src/installer/targets/registry.ts —— import + ALL_TARGETS 末尾追加 codebuddyTarget

# 3. 构建 + 全局链接（需 Node，注意官方 engines 要求 node <25）
npm install
npm run build
npm link            # 使全局 codegraph 命令可用

# 4. 写入 CodeBuddy 配置（-y 非交互，避免卡 @clack/prompts；必须 --location=global）
codegraph install --target=codebuddy --location=global -y

# 5. 在你的项目里建图谱
cd /path/to/your/project
codegraph init

# 6. 重启 CodeBuddy → MCP 列表出现 codegraph，工具 codegraph_explore/search/callers 可用
```

## 验证

```bash
codegraph install --print-config codebuddy   # 不写盘，仅打印将写入的配置
codegraph status                              # 查看图谱状态 / [OK] up to date
```

写入后的配置形如：
```json
{
  "mcpServers": {
    "codegraph": {
      "type": "stdio",
      "command": "codegraph",
      "args": ["serve", "--mcp", "--path", "${workspaceFolder}"]
    }
  }
}
```

## 兜底（重启后工具报 "not initialized"）

说明 CodeBuddy **不展开 `${workspaceFolder}`**。把那行 `--path` 改成**绝对路径**即可：
```json
"args": ["serve", "--mcp", "--path", "f:\\path\\to\\your\\project"]
```
缺点：写死单项目；多项目则每项目一条，或等 CodeBuddy 支持变量展开。
