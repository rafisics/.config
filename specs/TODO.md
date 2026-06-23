---
next_project_number: 767
---

# TODO

## Task Order

*Updated 2026-06-23. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,766 | -- | agent-system, Terminal UI, Email Integration |

**Grouped by Topic** (indented = depends on parent):

### Agent System

766 [NOT STARTED] — The dispatch-agent.sh script generates JSON dispatch instructions

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 766. Modernize agent dispatch architecture for current Claude Code capabilities
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: The dispatch-agent.sh script generates JSON dispatch instructions that skill-orchestrate interprets to make Agent tool calls — an indirection layer designed for a hypothetical future named-fork API. As of June 2026, Claude Code supports: (1) subagent_type fork for cache-warm context inheritance, (2) parallel Agent calls in a single message, (3) the Workflow tool with pipeline()/parallel()/agent() primitives for deterministic multi-agent orchestration. Research whether: (a) dispatch-agent.sh should be simplified to direct Agent tool calls, (b) MT orchestration should use the Workflow tool instead of the 400+ lines of bash pseudocode in MT-1 through MT-5, (c) fork patterns should be used more broadly for operations that benefit from cache sharing. Goal: reduce complexity while improving reliability and leveraging current platform capabilities. This task may supersede task 765 if MT mode is refactored.

---

### 765. Fix multi-task orchestration wave cycling and agent tracking
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [765_fix_mt_orchestration_wave_cycling/reports/01_mt-wave-cycling-research.md]
- **Plan**: [765_fix_mt_orchestration_wave_cycling/plans/01_mt-wave-cycling-plan.md]
- **Summary**: [765_fix_mt_orchestration_wave_cycling/summaries/01_mt-wave-cycling-summary.md]

**Description**: The skill-orchestrate MT mode (Stages MT-3 through MT-4) dispatches one phase per wave iteration but does not cycle back to dispatch the next phase. When all tasks start as [not_started], Wave 0 dispatches research for all, but after research completes the wave loop exits without dispatching planning or implementation. The orchestrator also loses track of parallel Agent completions — the user had to manually prompt that planner agents had finished after 8+ minutes of churning. Fix the wave loop to cycle through all lifecycle phases (research -> plan -> implement) until all tasks reach terminal state, and ensure parallel Agent calls are properly awaited and their completions processed.

---

### 764. Harden implementation agent plan marker enforcement
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [764_harden_plan_marker_enforcement/reports/01_plan-marker-research.md]
- **Plan**: [764_harden_plan_marker_enforcement/plans/01_plan-marker-plan.md]
- **Summary**: [764_harden_plan_marker_enforcement/summaries/01_plan-marker-summary.md]

**Description**: The general-implementation-agent has plan marker update instructions (Stage 4A marks [IN PROGRESS], Stage 4D marks [COMPLETED]) but implementation agents dispatched via /orchestrate multi-task mode do not reliably follow them. The top-level **Status** and phase headings remain [NOT STARTED] after implementation completes. Add a mandatory post-implementation verification step that checks all completed phases have [COMPLETED] markers in the plan file, and that the top-level Status reflects overall completion. Make this a hard contract rather than a soft instruction.

---

### 763. Add --lit integration test script
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 761, Task 762

**Description**: Create a test/verification script that validates the full --lit pipeline: (a) literature-briefing.sh produces non-empty output given a valid specs/literature-index.json, (b) cslib skills parse lit_flag and call briefing script, (c) agent prompts contain <literature-briefing> block instructions when lit_flag=true, (d) missing sub-index triggers the interactive setup detection prompt rather than silent failure. Place the script in .claude/scripts/test-lit-pipeline.sh.

---

### 762. Add literature-briefing injection points to CSLib agents
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: None

**Description**: Add <literature-briefing> block injection points to the 4 CSLib agent prompt templates: cslib-research-agent.md, cslib-implementation-agent.md, cslib-research-hard-agent.md, cslib-implementation-hard-agent.md. Follow the pattern from skill-researcher (lines 264-270) and skill-implementer (lines 258-264): inject lit_context after memory context and before task-specific instructions. The cslib-research-agent already references literature conceptually (lines 160-173) but lacks the actual injection point for the <literature-briefing> block generated by the skills.

---

### 761. Wire Stage 4a literature injection into CSLib skills
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: None

**Description**: Add Stage 4a literature briefing wiring to all 4 CSLib skill files: skill-cslib-research/SKILL.md, skill-cslib-implementation/SKILL.md, skill-cslib-research-hard/SKILL.md, skill-cslib-implementation-hard/SKILL.md. Follow the exact pattern from skill-researcher/SKILL.md (lines 146-180) and skill-implementer/SKILL.md (lines 139-173): check lit_flag, call literature-briefing.sh, capture lit_context. Currently these skills receive lit_flag as metadata but never trigger content injection.

---

### 760. Add interactive literature index setup detection to --lit flag
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: None

**Description**: When --lit is used and specs/literature-index.json does not exist, detect this in the flag processing path (skill-base.sh or command preflight) and present an interactive AskUserQuestion prompt asking if the user wants to set up the literature index. If yes, offer two choices: (a) create a research task to determine what literature entries are relevant to this repo and stop, or (b) create the task AND fork-orchestrate it inline, resuming the original work after the index is populated. The research task should scan the global ~/Projects/Literature/index.json, analyze the repo's task descriptions and domain, and produce a populated specs/literature-index.json. This replaces the current silent-exit behavior where --lit has no effect on repos without a sub-index.

---

### 87. Investigate terminal directory change when opening neovim in wezterm
- **Effort**: TBD
- **Status**: [RESEARCHED]
- **Task Type**: neovim
- **Topic**: Terminal UI
- **Dependencies**: None
- **Research**: [087_investigate_wezterm_terminal_directory_change/reports/research-001.md]

**Description**: Investigate why the terminal working directory changes to a project root when opening neovim sessions in wezterm from the home directory (~). Determine whether this behavior is caused by neovim or wezterm (configured in ~/.dotfiles/config/). Identify if any functionality depends on this behavior before modifying it. Goal is to avoid changing the terminal directory unless necessary.

---

### 78. Fix Himalaya SMTP authentication failure when sending emails
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: neovim
- **Topic**: Email Integration
- **Dependencies**: None
- **Research**: [078_fix_himalaya_smtp_authentication_failure/reports/research-001.md]
- **Plan**: [078_fix_himalaya_smtp_authentication_failure/plans/implementation-001.md]

**Description**: Fix Gmail SMTP authentication failure when sending emails via Himalaya (<leader>me). Error: Authentication failed: Code: 535, Enhanced code: 5.7.8, Message: Username and Password not accepted. The error occurs with TLS connection attempts and persists through multiple retry attempts. Identify and fix the root cause of the SMTP credential configuration.
