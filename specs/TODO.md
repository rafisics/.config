---
next_project_number: 777
---

# TODO

## Task Order

*Updated 2026-06-24. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,772,775 | -- | agent-system, literature, Terminal UI, ... |
| 2 | 773,776 | 772,775 | agent-system, literature |
| 3 | 774 | 773 | agent-system |

**Grouped by Topic** (indented = depends on parent):

### Agent System

772 [NOT STARTED] — Make skill-orchestrate-hard structurally incapable of doing imple
  └─ 773 [NOT STARTED] — The anti-analysis contract (H2, .claude/context/contracts/anti-an
    └─ 774 [NOT STARTED] — Make each --hard dispatch a genuinely small, bounded unit rather 

### Literature

775 [NOT STARTED] — Make literature-briefing.sh fall back to the global Literature co
  └─ 776 [NOT STARTED] — Two coupled fixes so --lit works outside the formal /research N -

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 776. Make --lit navigation work for ad-hoc dispatch and sync stale CLAUDE.md docs
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 775

**Description**: Two coupled fixes so --lit works outside the formal /research N --lit command path and is documented accurately. (1) Ad-hoc dispatch directive: create a reusable "literature navigation directive" (e.g. a short context snippet or a thin script wrapper) that the primary/orchestrator agent can inject into ANY dispatched agent prompt when the user asks for --lit conversationally (not via skill Stage 4a) -- it should carry the same <literature-briefing> navigation instructions (run literature-search.sh against the global corpus, Read the relevant segmented chunk files) so a conversationally-dispatched research agent is actually directed to explore the index. Reference how Stage 4a generates lit_context. (2) CLAUDE.md doc sync: the "Literature Mode (--lit)" section still describes the DEPRECATED static-dump model (literature-retrieve.sh, <literature-context>, "reads all .md and .txt files from specs/literature/", TOKEN_BUDGET=4000/MAX_FILES=10). Rewrite the "What --lit Does" subsection to describe the live navigate-on-demand briefing (literature-briefing.sh -> <literature-briefing>) against the global segmented corpus, including the new global-corpus fallback from Task 775. Also reconcile the token-budget drift (literature-retrieve.sh header says 8000, CLAUDE.md says 4000, global index.json says 8000). Root causes: G3 (navigation reachable only from skill Stage 4a), G4 (stale CLAUDE.md misdocuments --lit). Depends on Task 775 (documents the fallback behavior 775 implements).

---

### 775. Add global-corpus fallback to --lit so the briefing is never empty
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: None

**Description**: Make literature-briefing.sh fall back to the global Literature corpus when the per-repo specs/literature-index.json sub-index is absent, instead of silently exiting empty. Specifically: (1) When no sub-index exists (or it has zero entries), run a NON-INTERACTIVE relevance search against the global ~/Projects/Literature FTS5 index (via literature-search.sh, keyed by the task description / task_type passed from the skill) and build a <literature-briefing> from the top-N matching segments (paths + chunk counts + token totals + the existing "How to Use" navigation footer). (2) Ensure the briefing always lists how to call literature-search.sh and Read chunk files so the agent actively explores the segmented sources. (3) Thread the task description/query into literature-briefing.sh (it currently takes no arguments) so the fallback search is relevant. (4) Update the skill Stage 4a callers (skill-researcher, skill-researcher-hard, skill-planner, skill-planner-hard, skill-implementer, skill-implementer-hard) so the fallback briefing is generated and injected even when the interactive sub-index setup is skipped -- keep the interactive "curate sub-index" path as an optional enhancement, not a precondition. Root causes: G1 (hard gate + silent empty exit), G2 (no global-corpus fallback). Goal: --lit reliably directs the agent to the segmented global sources without requiring a pre-curated per-repo sub-index. CONTEXT: User asked a primary agent (conversationally) to invoke a research agent with --lit on a difficult Lean proof in ~/Projects/cslib/ (transcript: .claude/output/lit.md). The live --lit mechanism (literature-briefing.sh, which superseded the deprecated static-dump literature-retrieve.sh) already does navigate-on-demand correctly, but in lit.md the briefing never reached the agent because literature-briefing.sh is hard-gated on a per-repo sub-index that did not exist and silently exited empty, and there is no global-corpus fallback. The global ~/Projects/Literature (222 entries in index.json + queryable FTS5 .literature.db via literature-search.sh + per-doc chunks.json TOC) was never explored.

---

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
