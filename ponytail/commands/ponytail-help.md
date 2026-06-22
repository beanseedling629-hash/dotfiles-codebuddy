# /ponytail-help — 命令速查

输出 ponytail 系列命令的快速参考。

## 执行

直接打印下表：

```
/ponytail [lite|full|ultra|off]  切换防过度工程强度（默认 full）
/ponytail-review                 审查当前 diff 的过度工程，给删除/简化清单
/ponytail-audit                  审计整个仓库的过度工程，给分级精简清单
/ponytail-debt                   汇总代码中 `ponytail:` 延后标记成账本
/ponytail-help                   显示本速查
```

核心理念：最好的代码是你从未写过的代码。判断阶梯：
需要存在吗 → 标准库 → 原生平台 → 已装依赖 → 一行 → 最小实现。
安全红线（校验/错误处理/安全/可访问性）任何时候都不牺牲。

规则文件：`~/.codebuddy/rules/ponytail.md`
