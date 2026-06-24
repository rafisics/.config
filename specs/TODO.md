---
next_project_number: 778
---

# TODO

## Task Order

*Updated 2026-06-24. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,772,774,775,777 | -- | agent-system, literature, Terminal UI, ... |
| 2 | 773,776 | 772,775 | agent-system, literature |

**Grouped by Topic** (indented = depends on parent):

### Agent System

772 [NOT STARTED] — [--hard IMPLEMENTATION leg: focus each agent round on an INDIVIDU
  └─ 773 [NOT STARTED] — The anti-analysis contract (H2, .claude/context/contracts/anti-an
774 [NOT STARTED] — [--hard PLANNING leg: make phases SMALLER and divide work into a 
777 [NOT STARTED] — [--hard RESEARCH leg: more effort, higher standards for quality, 

### Literature

775 [NOT STARTED] — [--lit, NO SILENT FALLBACK] When --lit is used but no per-repo sp
  └─ 776 [NOT STARTED] — Two coupled fixes so --lit works outside the formal /research N -

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 777. Hard-mode research: more effort, higher quality and verification standards
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: [--hard RESEARCH leg: more effort, higher standards for quality, consistency, and verification of findings.] Strengthen hard-mode research (skill-researcher-hard / general-research-hard-agent, and domain research-hard agents where applicable) so --hard research is materially more rigorous than standard research, not just a relabel. (1) Raise the effort/coverage bar: require broader source coverage and deeper investigation before concluding (more searches, cross-checking multiple independent sources, no single-source conclusions). (2) Higher quality + consistency standards: require findings to be internally consistent and cross-validated; surface and RESOLVE contradictions rather than reporting them flatly. (3) Harden VERIFICATION of findings: extend the existing H4 adversarial self-verification and H3 reference grounding so every load-bearing claim is verified against a concrete source or counterexample before it ships, and uncertain claims are explicitly marked with confidence levels. (4) Encode the higher standard as enforceable CONTRACT language (analogous to the anti-analysis contract), in the research-hard skill/agent and any research-hard contract file, not just prose. Scope: hard-mode only; do NOT change standard research. CONTEXT: completes the three-leg --hard model alongside the implementation leg (task 772) and the planning leg (task 774). Motivating evidence: in transcript .claude/output/lit.md a hasty inline (non-hard) research conclusion was later found UNSOUND by a more careful standard-mode audit -- hard research should make that level of verification the default, raising confidence in the findings that drive planning and implementation.

---

### 776. Make --lit navigation work for ad-hoc dispatch and sync stale CLAUDE.md docs
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 775

**Description**: Two coupled fixes so --lit works outside the formal /research N --lit command path and is documented accurately. (1) Ad-hoc dispatch directive: create a reusable 'literature navigation directive' that the primary/orchestrator agent injects when the user asks for --lit conversationally (not via skill Stage 4a). When no per-repo sub-index exists, this path must surface the SAME interactive question defined in task 775 (create curation task vs use global now) -- it must NOT silently inject nothing and must NOT silently auto-search. Once a path is chosen, the dispatched agent receives the <literature-briefing> navigation instructions (run literature-search.sh against the chosen corpus, Read the relevant segmented chunk files). Reference how Stage 4a generates lit_context. (2) CLAUDE.md doc sync: the 'Literature Mode (--lit)' section still describes the DEPRECATED static-dump model (literature-retrieve.sh, <literature-context>, 'reads all .md and .txt files from specs/literature/', TOKEN_BUDGET=4000/MAX_FILES=10). Rewrite the 'What --lit Does' and 'Interactive Sub-Index Setup Detection' subsections to describe (i) the live navigate-on-demand briefing (literature-briefing.sh -> <literature-briefing>) against the global segmented corpus, and (ii) the interactive no-silent-fallback behavior from task 775 (create-curation-task vs use-global-now). Reconcile the token-budget drift (literature-retrieve.sh header 8000, CLAUDE.md 4000, global index.json 8000). Root causes: G3 (navigation reachable only from skill Stage 4a), G4 (stale CLAUDE.md misdocuments --lit). Depends on task 775 (documents the interactive behavior 775 implements).

---

### 775. --lit: interactive prompt when no per-repo sub-index (no silent fallback)
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: None

**Description**: [--lit, NO SILENT FALLBACK] When --lit is used but no per-repo specs/literature-index.json sub-index exists, the system MUST present an INTERACTIVE question (AskUserQuestion) -- never silently do nothing, and never silently auto-search. The question asks the user to choose between: (a) CREATE A TASK to curate a per-repo sub-index (so future --lit runs use a focused, repo-specific selection from the global corpus), or (b) POINT TO THE GLOBAL corpus now (run a relevance search against the global ~/Projects/Literature FTS5 index via literature-search.sh, keyed by the task description, and build a <literature-briefing> from the top-N matching segments for this run). (1) literature-briefing.sh must accept the task description/query (it currently takes no arguments) and support a global-corpus briefing mode used by option (b). (2) Wire the interactive prompt into the skill Stage 4a callers (skill-researcher, skill-researcher-hard, skill-planner, skill-planner-hard, skill-implementer, skill-implementer-hard) -- reconcile with / replace the existing 3-option Stage 4a flow (Skip / Create setup task / Create+run) so the choice is clearly 'create curation task' vs 'use global now', and NO branch silently yields an empty briefing. (3) Either briefing path always carries the 'How to Use' footer directing the agent to run literature-search.sh and Read the relevant segmented chunk files. (4) DESIGN QUESTION to resolve during /plan: define the default for autonomous contexts (e.g. /orchestrate) where AskUserQuestion cannot prompt -- it must be a VISIBLE, logged choice (e.g. default to global with a logged notice, or create-and-defer), never a silent no-op. Root causes: G1 (hard gate + silent empty exit), G2 (no global-corpus option). SUPERSEDES the earlier non-interactive auto-fallback design per user direction: 'I don't like fallbacks which are silent.' CONTEXT: transcript .claude/output/lit.md -- no sub-index existed, briefing silently exited empty, the agent got nothing from --lit and fell back to web/training knowledge; the segmented global corpus (222 entries + queryable FTS5 .literature.db via literature-search.sh) was never explored.

---

### 774. Hard-mode planning: smaller phases + skeleton plan with follow-up tasks
- **Effort**: 3-6 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: [--hard PLANNING leg: make phases SMALLER and divide work into a SKELETON plan + follow-up tasks.] Revise hard-mode planning (skill-planner-hard / planner-hard-agent) so that under --hard the plan is decomposed into genuinely small phases, each completable in one bounded agent round, rather than one large open-ended plan ('Phase 1 strike 3: prove merge_forward_succ' was research-grade). (1) Tighten H8 phase sizing so each phase is a minimal bounded unit (e.g. one lemma / one checklist sub-item / ~100-300 lines output), not a multi-part objective. (2) Add a SKELETON-PLUS-FOLLOW-UP decomposition: when the full objective exceeds what a few small phases can cover, planner-hard produces a SKELETON plan covering the core/critical path and SPAWNS follow-up tasks (via the task-spawn / multi-task-creation mechanism) for the remaining work, instead of inflating phases. The skeleton plan and its follow-up tasks are linked via state.json dependencies. (3) Ensure the resulting small phases feed the implementation leg (task 772) so each implement round handles exactly one phase. (4) Extend the handoff schema (.claude/context/contracts/wrap-up.md) as needed to track skeleton-vs-follow-up status, and update skill-implementer-hard Stage 3b to consume the smaller phases. Root cause: RC4 (phases not regimented; oversized open-ended phases drove orchestrator burnout on task 305). Scope: hard-mode only. CONTEXT: part of making --hard proceed in regimented bounded chunks (transcript /orchestrate 305 --hard --lit, .claude/output/hard.md). This is the PLANNING leg of the three-leg --hard model (research=task 777, planning=this task, implementation=task 772).

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

**Description**: [--hard IMPLEMENTATION leg: focus each agent round on an INDIVIDUAL PHASE, never the entire plan.] Make skill-orchestrate-hard structurally incapable of doing implementation work itself, forcing per-phase delegation. (1) Remove `Edit` from skill-orchestrate-hard `allowed-tools` (currently `Agent, Bash, Read, Edit`) so the orchestrator cannot directly modify source files -- it used Update ~10 times on task 305. (2) Constrain Bash to orchestration-only operations (jq/state.json reads, git status/log, status-sync scripts) and explicitly forbid build/test/compiler invocations (lake build, lean-lsp, etc.) in the orchestrator context. (3) Require BLOCKING, foreground single-phase dispatch: exactly one Agent call per cycle, wait for its handoff return, never interleave the orchestrator's own work -- forbid background/parallel dispatch of implementation agents (root cause: transcript line 92 'launched it in the background and will continue the orchestration'). (4) Restrict orchestrator Reads to handoff JSON, state.json, and plan files ONLY -- forbid reading implementation source files. Root causes: RC1 (orchestrator had Edit + unrestricted Bash), RC3 (H1 not enforced as a hard loop boundary; background dispatch). Scope: hard-mode only; do NOT modify base skill-orchestrate. CONTEXT: /orchestrate 305 --hard --lit (transcript .claude/output/hard.md) -- the orchestrator became the implementation agent (lines 954-2700: zero implementation dispatches, only inline proof reasoning + ~10 direct Update/lake-build/lean-lsp calls). Goal: each --hard implementation round dispatches exactly ONE phase to a bounded sub-agent; the orchestrator never takes the plan as a whole. Pairs with the planning leg (task 774), which produces the small phases this leg consumes.

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
