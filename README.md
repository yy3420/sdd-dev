# sdd-dev

> 一套可直接安装到 Claude Code 的 **SDD（Spec-Driven Development，规格驱动开发）** 工作流。

它把开发过程拆成六个阶段：

```text
spec → ui → plan → tasks → implement → review
```

通过 Claude Code 的 slash commands 强制“先规格、再界面设计、再计划、再任务、再实现、最后验收”，避免 AI 一上来就写代码。

---

## 特性

- 六个内置命令：`/sdd-spec`、`/sdd-ui`、`/sdd-plan`、`/sdd-tasks`、`/sdd-implement`、`/sdd-review`
- UI 设计阶段产出 `ui-design.md` + 可直接打开的静态 HTML 原型，并把设计中发现的需求缺口回流到 spec
- 支持 **项目级安装** 和 **全局安装**
- 每个阶段都有明确门禁，规格不清不进入下一步
- 每个任务必须可验证，包含验收标准和验证命令
- 兼容 Claude Code；Claude 网页版可手动按同样流程使用
- 纯 Markdown + Shell 脚本，无额外依赖

---

## 快速开始

### 方式一：一键安装到当前项目

在项目根目录执行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yy3420/sdd-dev/main/install-sdd.sh)
```

安装完成后，当前项目会多出：

```text
CLAUDE.md
.claude/commands/sdd-spec.md
.claude/commands/sdd-ui.md
.claude/commands/sdd-plan.md
.claude/commands/sdd-tasks.md
.claude/commands/sdd-implement.md
.claude/commands/sdd-review.md
specs/
```

### 方式二：克隆后安装

```bash
git clone https://github.com/yy3420/sdd-dev.git
cd sdd-dev
bash ./install-sdd.sh
```

### 全局安装

如果你希望所有项目都能使用这套命令：

```bash
bash install-sdd.sh global
```

全局安装会写入：

```text
~/.claude/commands/
~/.claude/CLAUDE.md
```

---

## 使用

重启 Claude Code，输入 `/`，应该能看到：

```text
/sdd-spec
/sdd-ui
/sdd-plan
/sdd-tasks
/sdd-implement
/sdd-review
```

然后按顺序执行：

```text
/sdd-spec 我想做一个用户登录功能
/sdd-ui
/sdd-plan
/sdd-tasks
/sdd-implement
/sdd-review
```

### 命令说明

| 命令 | 作用 | 产出 |
| --- | --- | --- |
| `/sdd-spec` | 根据需求生成规格 | `specs/<编号>-<slug>/spec.md` |
| `/sdd-ui` | 基于 spec 做 UI 设计，并回流需求缺口 | `ui-design.md` + `prototypes/*.html`，确认后更新 `spec.md` |
| `/sdd-plan` | 基于 spec（和 ui-design）生成技术计划 | `specs/<编号>-<slug>/plan.md` |
| `/sdd-tasks` | 基于 spec + plan 拆任务 | `specs/<编号>-<slug>/tasks.md` |
| `/sdd-implement` | 按任务清单循环实现 | 代码 + 更新后的 `tasks.md` |
| `/sdd-review` | 对照 spec 做最终验收 | 验收报告 |

### UI 设计阶段

`/sdd-ui` 是需求和计划之间的必经阶段：

1. 判断需求是否含界面交互。纯后端 / CLI / 库类需求会说明理由后跳过，并在 `spec.md` 记录跳过原因。
2. 产出 `ui-design.md`：页面清单与信息架构、布局、组件、交互流程、状态设计（空 / 加载 / 错误）、响应式、视觉规范、可访问性。
3. 在 `prototypes/` 下生成静态 HTML 原型，浏览器可直接打开，无需构建工具。
4. 输出「需求补充建议」——设计过程中发现的 FR / AC 缺口，**等你确认后**才写回 `spec.md`。

第 4 步是这个阶段的关键：UI 设计往往暴露出规格里没写清的状态和边界，这些必须先回到 spec，再进入 plan。

---

## 核心规则

`CLAUDE.md` 中定义了 SDD 工作流必须遵守的规则，核心是：

1. `spec.md` 是唯一事实来源。
2. 未确认 spec，不进入 UI 设计。
3. 含界面交互的需求必须先完成 UI 设计，未确认 UI 设计不进入 plan。
4. 纯后端 / CLI / 库类需求可跳过 UI 设计，但必须在 `spec.md` 中记录跳过理由。
5. UI 设计完成后先产出「需求补充建议」，经确认后才写回 `spec.md`，不得擅自改需求。
6. 未确认 plan，不进入 tasks。
7. 未完成任务，不开始下一个任务。
8. 禁止一次性生成大量实现代码。
9. 每个任务必须可独立验证，包含验收标准和验证命令。
10. 实现前先写/更新测试，或至少明确验证方式。
11. 每次修改后运行测试、lint、typecheck。
12. 发现需求歧义，先提问，不猜测。
13. 如果实现中发现 spec 有问题，暂停并更新 spec，而不是偷偷改需求。

---

## 目录结构

```text
sdd-dev/
├── install-sdd.sh
├── CLAUDE.md
├── .claude/
│   └── commands/
│       ├── sdd-spec.md
│       ├── sdd-ui.md
│       ├── sdd-plan.md
│       ├── sdd-tasks.md
│       ├── sdd-implement.md
│       └── sdd-review.md
├── specs/
│   └── 001-example/
│       ├── spec.md
│       ├── ui-design.md
│       ├── prototypes/
│       │   └── login.html
│       ├── plan.md
│       └── tasks.md
├── LICENSE
└── README.md
```

---

## Claude 网页版

Claude 网页版不能安装 slash command，但可以这样使用：

1. 新建一个 Project。
2. 把 `CLAUDE.md` 内容粘贴到 **Project instructions**。
3. 把 `.claude/commands/*.md` 上传为 **Project files**。
4. 对话时手动写：

```text
按 sdd-spec 执行：我想做一个用户登录功能
```

---

## 自定义

你可以直接编辑 `.claude/commands/*.md` 来调整各阶段提示词。

例如：

- 修改 `sdd-spec.md` 增加公司内部需求模板
- 修改 `sdd-ui.md` 指定设计系统、组件库和品牌色
- 修改 `sdd-tasks.md` 调整任务粒度
- 修改 `sdd-implement.md` 指定必须运行的测试命令

修改后重启 Claude Code 即可生效。

---

## 适合谁

- 用 Claude Code 做项目，但希望 AI 不要乱写代码
- 想用 SDD / Spec-Driven Development 约束开发流程
- 需要把需求、计划、任务、实现、验收串成闭环
- 团队内想统一 AI 辅助开发的工作方式

---

## License

MIT