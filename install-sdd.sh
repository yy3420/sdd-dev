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
2. 未确认 spec，不进入 UI 设计。
3. 含界面交互的需求必须先完成 UI 设计（ui-design.md + prototypes/），未确认 UI 设计不进入 plan。
4. 纯后端 / CLI / 库类需求可跳过 UI 设计，但必须在 spec.md 中记录跳过理由。
5. UI 设计完成后先产出「需求补充建议」，经我确认后才写回 spec.md，不得擅自改需求。
6. 未确认 plan，不进入 tasks。
7. 未完成任务，不开始下一个任务。
8. 禁止一次性生成大量实现代码。
9. 每个任务必须可独立验证，包含验收标准和验证命令。
10. 实现前先写/更新测试，或至少明确验证方式。
11. 每次修改后运行测试、lint、typecheck。
12. 发现需求歧义，先提问，不猜测。
13. 如果实现中发现 spec 有问题，暂停并更新 spec，而不是偷偷改需求。
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

cat > "$CMD_DIR/sdd-ui.md" <<'UI_EOF'
---
description: 基于 spec 生成 UI 设计
---

用户需求：$ARGUMENTS

读取最新 spec。

任务：
1. 先判断本需求是否含界面交互：
   - 纯后端 / CLI / 库类需求：说明理由后停止，并在 spec.md 中记录「跳过 UI 设计：<理由>」。
   - 含界面交互：继续以下步骤，本阶段必经。
2. 阅读 spec.md、现有代码与既有 UI 规范。
3. 如果关键信息缺失，先问我最多 5 个问题，不要自行假设视觉风格与交互细节。
4. 创建 specs/<编号>-<slug>/ui-design.md，包含：
   - 设计目标与设计原则
   - 页面清单与信息架构
   - 每页布局与区域划分（文字或 ASCII 线框）
   - 组件清单（复用来源、状态、变体）
   - 交互流程（用户路径、跳转、反馈）
   - 状态设计：默认 / 空 / 加载 / 错误 / 无权限 / 边界数据
   - 响应式与断点策略
   - 视觉规范：色彩、字体、间距、圆角、图标
   - 可访问性：对比度、焦点可见、键盘操作、语义标签
5. 在 specs/<编号>-<slug>/prototypes/ 下生成静态 HTML 原型：
   - 每个主要页面一个 HTML 文件，浏览器可直接打开
   - 内联样式，不引入构建工具和外部依赖
   - 覆盖 ui-design.md 中的关键状态（至少默认态与空态）
6. 输出「需求补充建议」清单，用于重新完善需求：
   - 新增 FR / 修改 FR / 新增 AC / 修改 AC
   - 每条注明来源（UI 设计发现）和理由
   - 暂停并等我确认；确认后写回 spec.md，并在 spec.md 记录变更说明
7. 汇报：产出文件路径、需求补充建议、需要我确认的决策。

禁止：写业务实现代码、修改 plan.md 和 tasks.md。
未确认 UI 设计，不进入 plan。
UI_EOF

cat > "$CMD_DIR/sdd-plan.md" <<'PLAN_EOF'
---
description: 基于 spec 生成技术计划
---

读取最新 spec，若存在 ui-design.md 则一并读取。

任务：
生成 specs/<编号>-<slug>/plan.md，包含：
- 技术栈与依赖
- 架构与模块划分
- 数据模型
- API / 接口契约
- 前端组件划分（须与 ui-design.md 的页面、组件、状态逐项对应）
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

读取 spec.md 和 plan.md，若存在 ui-design.md 则一并读取。

任务：
生成 specs/<编号>-<slug>/tasks.md。
要求：
- 每个任务 30-90 分钟可完成
- 按依赖排序
- 优先垂直切片，而不是按层拆分
- 每个任务包含：ID、依赖、涉及文件、验收标准、验证命令
- 涉及界面的任务须注明对应的 ui-design.md 页面、组件与状态
- 格式：- [ ] T001 ...

禁止：写实现代码。
TASKS_EOF

cat > "$CMD_DIR/sdd-implement.md" <<'IMPL_EOF'
---
description: 按 tasks.md 循环实现
---

读取 spec.md、plan.md、tasks.md，若存在 ui-design.md 则一并读取。

先梳理下任务中是否有发现规格不清或者需要确认的，如果有则先进行确认，之后再循环执行并更新spec

循环执行：
1. 找到下一个未完成任务。
2. 先写/更新测试，或明确验证方式。
3. 做最小实现。
4. 运行验证命令。
5. 更新 tasks.md，勾选任务。
6. 汇报：改了什么、验证结果、下一步。

尽可能保证循环的连贯性.
不要跳过验证。不要同时做多个任务。
IMPL_EOF

cat > "$CMD_DIR/sdd-review.md" <<'REVIEW_EOF'
---
description: 对照 spec 做最终验收
---

读取 spec.md、plan.md、tasks.md 和当前代码，若存在 ui-design.md 则一并读取。

任务：
1. 逐条检查验收标准 AC。
2. 若有 ui-design.md，逐页核对实现与设计是否一致：页面、组件、状态（空/加载/错误）、响应式、可访问性。
3. 运行完整测试、lint、typecheck。
4. 列出未完成项、风险、回归点。
5. 给出是否可以交付的结论。
REVIEW_EOF

echo "✅ SDD 已安装"
echo "项目级：重启 Claude Code，输入 / 查看 sdd-* 命令"
echo "全局安装：保存为 install-sdd.sh 后运行 bash install-sdd.sh global"