#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-project}"

if [ "$MODE" = "global" ]; then
  CMD_DIR="$HOME/.claude/commands"
  MEM_FILE="$HOME/.claude/CLAUDE.md"
else
  CMD_DIR="$(pwd)/.claude/commands"
  MEM_FILE="$(pwd)/CLAUDE.md"
fi

mkdir -p "$CMD_DIR" specs

cat > "$MEM_FILE" <<'CLAUDE_EOF'
# SDD 工作流规则

你是本项目的 SDD 执行代理，必须遵守：

1. spec.md 是唯一事实来源。
2. 未确认 spec，不进入 plan。
3. 未确认 plan，不进入 tasks。
4. 未完成任务，不开始下一个任务。
5. 禁止一次性生成大量实现代码。
6. 每个任务必须可独立验证，包含验收标准和验证命令。
7. 实现前先写/更新测试，或至少明确验证方式。
8. 每次修改后运行测试、lint、typecheck。
9. 发现需求歧义，先提问，不猜测。
10. 如果实现中发现 spec 有问题，暂停并更新 spec，而不是偷偷改需求。
CLAUDE_EOF

cat > "$CMD_DIR/sdd-spec.md" <<'SPEC_EOF'
---
description: 根据需求生成 SDD 规格
---

用户需求：$ARGUMENTS

任务：
1. 阅读现有 specs 和相关代码，但不要写实现代码。
2. 如果关键信息缺失，先问我最多 5 个问题。
3. 创建 specs/<三位编号>-<slug>/spec.md，包含：
   - 背景
   - 目标
   - 非目标
   - 用户故事
   - 功能需求 FR-1, FR-2...
   - 非功能需求 NFR-1...
   - 验收标准 AC-1，使用 Given/When/Then
   - 边界与异常
   - 开放问题
4. 输出文件路径、开放问题、需要我确认的决策。

禁止：写业务代码、修改实现。
SPEC_EOF

cat > "$CMD_DIR/sdd-plan.md" <<'PLAN_EOF'
---
description: 基于 spec 生成技术计划
---

读取最新 spec。

任务：
生成 specs/<编号>-<slug>/plan.md，包含：
- 技术栈与依赖
- 架构与模块划分
- 数据模型
- API / 接口契约
- 测试策略
- 实施顺序
- 风险与回滚方案

禁止：写实现代码。
完成后列出需要我确认的技术决策。
PLAN_EOF

cat > "$CMD_DIR/sdd-tasks.md" <<'TASKS_EOF'
---
description: 基于 spec 和 plan 生成任务清单
---

读取 spec.md 和 plan.md。

任务：
生成 specs/<编号>-<slug>/tasks.md。
要求：
- 每个任务 30-90 分钟可完成
- 按依赖排序
- 优先垂直切片，而不是按层拆分
- 每个任务包含：ID、依赖、涉及文件、验收标准、验证命令
- 格式：- [ ] T001 ...

禁止：写实现代码。
TASKS_EOF

cat > "$CMD_DIR/sdd-implement.md" <<'IMPL_EOF'
---
description: 按 tasks.md 循环实现
---

读取 spec.md、plan.md、tasks.md。

循环执行：
1. 找到下一个未完成任务。
2. 先写/更新测试，或明确验证方式。
3. 做最小实现。
4. 运行验证命令。
5. 更新 tasks.md，勾选任务。
6. 汇报：改了什么、验证结果、下一步。

如果发现规格不清，暂停并更新 spec。
不要跳过验证。不要同时做多个任务。
IMPL_EOF

cat > "$CMD_DIR/sdd-review.md" <<'REVIEW_EOF'
---
description: 对照 spec 做最终验收
---

读取 spec.md、plan.md、tasks.md 和当前代码。

任务：
1. 逐条检查验收标准 AC。
2. 运行完整测试、lint、typecheck。
3. 列出未完成项、风险、回归点。
4. 给出是否可以交付的结论。
REVIEW_EOF

echo "✅ SDD 已安装"
echo "项目级：重启 Claude Code，输入 / 查看 sdd-* 命令"
echo "全局安装：保存为 install-sdd.sh 后运行 bash install-sdd.sh global"