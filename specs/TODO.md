---
next_project_number: 775
---

# TODO

## Task Order

*Updated 2026-06-24. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,772 | -- | agent-system, Terminal UI, Email Integration |
| 2 | 773 | 772 | agent-system |
| 3 | 774 | 773 | agent-system |

**Grouped by Topic** (indented = depends on parent):

### Agent System

772 [NOT STARTED] — Make skill-orchestrate-hard structurally incapable of doing imple
  └─ 773 [NOT STARTED] — The anti-analysis contract (H2, .claude/context/contracts/anti-an
    └─ 774 [NOT STARTED] — Make each --hard dispatch a genuinely small, bounded unit rather 

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 774. Add regimented chunk-sizing and phase subdivision to hard-mode dispatch
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 773

**Description**: Make each --hard dispatch a genuinely small, bounded unit rather than a whole open-ended phase ('Phase 1 strike 3: prove merge_forward_succ' was research-grade). (1) Strengthen per-phase dispatch so each implement dispatch targets the SMALLEST next unit (one lemma / one plan checklist sub-item / bounded output), not an entire phase. (2) Add a subdivision mechanism in skill-orchestrate-hard: when a phase is too large, or a dispatch returns partial with zero progress (phases_delta == 0), dispatch the smallest next sub-goal rather than re-dispatching the whole phase. (3) Extend the handoff schema (.claude/context/contracts/wrap-up.md) with sub-phase/chunk tracking so progress is measured at chunk granularity. (4) Tie the planner-hard H8 sizing constraint (~100-500 lines, 'completable in one agent run') to an orchestrate-time per-dispatch output cap with a MANDATORY handoff at the cap; update skill-implementer-hard Stage 3b accordingly. Root cause: RC4 (chunks not regimented; H8 sizing lives only in planner with no subdivide-at-dispatch mechanism). Scope: hard-mode only. CONTEXT: part of making --hard enforce regimented bounded chunks (transcript /orchestrate 305 --hard --lit, .claude/output/hard.md) so the orchestrator never takes the plan as a whole.

---

### 773. Add orchestrator-role discipline contract and burnout circuit-breaker
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 772

**Description**: The anti-analysis contract (H2, .claude/context/contracts/anti-analysis.md) is injected only into IMPLEMENT dispatches via build_hard_mode_prompt_context -- the orchestrator ROLE itself is ungoverned, which is why burnout happened in the orchestrator's own context. Create a new contract (e.g. .claude/context/contracts/orchestrator-discipline.md) binding the orchestrator role: NO inline design/proof analysis, NO reading implementation source, NO running builds, NO strategy reconsideration; when a phase cannot complete in a bounded dispatch, the only allowed responses are (a) dispatch a fresh research/audit agent, or (b) escalate via the blocker ladder -- NEVER absorb the work. Wire this contract into skill-orchestrate-hard so it is referenced/enforced at the top of the state-machine loop (analogous to anti-analysis.md injection into implement dispatches). Add a burnout circuit-breaker: detect orchestrator context-exhaustion signals (repeated re-reads of the same file, multiple consecutive inline-reasoning turns with no Agent dispatch, mid-analysis strategy reversal) and force a handoff/dispatch instead of continuing inline. Reference existing context-exhaustion-detection.md if present. Root causes: RC2 (orchestrator role ungoverned by H2), RC5 (no burnout circuit-breaker). Scope: hard-mode only. CONTEXT: burnout signatures in transcript -- circular reconsideration (built renameNF_eval_dup -> doubted it -> abandoned -> re-added -> stripped -> re-added a hypothesis), explicit 'before I concede... ONE more time' (line 2009); ended marking phase BLOCKED with an UNSOUND inline conclusion later caught by a standard-mode audit.

---

### 772. Make hard-mode orchestrator a pure dispatcher (strip implementation capability)
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Make skill-orchestrate-hard structurally incapable of doing implementation work itself, forcing delegation. (1) Remove `Edit` from skill-orchestrate-hard `allowed-tools` (currently `Agent, Bash, Read, Edit`) so the orchestrator cannot directly modify source files -- it used Update ~10 times on task 305. (2) Constrain Bash to orchestration-only operations (jq/state.json reads, git status/log, status-sync scripts) and explicitly forbid build/test/compiler invocations (lake build, lean-lsp, etc.) in the orchestrator context. (3) Require BLOCKING, foreground single-phase dispatch: exactly one Agent call per cycle, wait for its handoff return, never interleave the orchestrator's own work -- forbid background/parallel dispatch of implementation agents (root cause: transcript line 92 'launched it in the background and will continue the orchestration'). (4) Restrict orchestrator Reads to handoff JSON, state.json, and plan files ONLY -- forbid reading implementation source files. Root causes: RC1 (orchestrator had Edit + unrestricted Bash), RC3 (H1 not enforced as a hard loop boundary; background dispatch). Scope: hard-mode only; do NOT modify base skill-orchestrate. CONTEXT: User ran /orchestrate 305 --hard --lit in BimodalLogic (transcript at .claude/output/hard.md). The orchestrator became the implementation agent (transcript lines 954-2700: zero implementation dispatches, only inline proof reasoning + ~10 direct Update/lake-build/lean-lsp calls). Goal: make --hard enforce regimented bounded chunks so the orchestrator never takes the plan as a whole.

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
