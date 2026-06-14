---
next_project_number: 694
---

# TODO

## Task Order

*Updated 2026-06-14. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,652,693 | -- | agent-system, Terminal UI, Email Integration |

**Grouped by Topic** (indented = depends on parent):

### Agent System

652 [NOT STARTED] — After ~1 week of the new pipeline running, review logs to verify 
693 [NOT STARTED] — The --lit flag is non-functional because literature-retrieve.sh d

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 693. Fix lit flag missing script
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: The --lit flag is non-functional because literature-retrieve.sh does not exist. Create .claude/scripts/literature-retrieve.sh that reads all .md and .txt files from specs/literature/ (up to TOKEN_BUDGET=4000 tokens, MAX_FILES=10), and outputs a <literature-context> block for injection into agent prompts. Verify integration points in skill-base.sh or skill preflight stages that call literature-retrieve.sh.

---

### 692. Persist description in task creation flows
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [692_persist_description_in_task_creation_flows/reports/01_research-description-persistence.md]
- **Plan**: [692_persist_description_in_task_creation_flows/plans/01_implementation-plan.md]
- **Summary**: [692_persist_description_in_task_creation_flows/summaries/01_execution-summary.md]

**Description**: Add description and title persistence to all task creation flows in state.json. Currently, the improved description computed during task creation is never stored, so TODO.md entries lack descriptions.

Root cause: The state.json task entry jq template omits description/title fields.

Affected locations (4 flows missing description):
1. commands/task.md step 6 (Create Task Mode) - improved description computed but not in jq template
2. agents/meta-builder-agent.md Stage 6 (CreateTasks) - has titles from interview, not persisted
3. skills/skill-fix-it/SKILL.md Step 9.1 - internal title/description not in state.json entry
4. commands/task.md expand mode (step 3) - uses same Create Task jq pattern

Reference: commands/task.md --review mode (step 8) correctly includes description - use as template.

Fix: Add "description": $desc (and optionally "title": $title) to each state.json entry template. The generate-todo.sh script already renders descriptions when present - no changes needed there.

---

### 691. Document --lit flag in CLAUDE.md and command reference
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 689, Task 690
- **Research**: [691_document_lit_flag_claude_md/reports/01_document-lit-flag.md]
- **Plan**: [691_document_lit_flag_claude_md/plans/01_document-lit-flag-plan.md]
- **Summary**: [691_document_lit_flag_claude_md/summaries/01_document-lit-flag-summary.md]

**Description**: Add --lit flag documentation to: (1) CLAUDE.md merge source Command Reference table (add --lit to /research, /plan, /implement, /orchestrate usage patterns). (2) CLAUDE.md merge source Hard Mode section or new Literature Mode section describing the --lit flag behavior. (3) Update the EXTENSION.md if the memory extension documents --clean in a way that --lit should parallel. (4) Add a specs/literature/ directory convention note explaining what files should be placed there and how they are consumed. Regenerate CLAUDE.md after updating merge sources.

---

### 690. Wire --lit flag through /research, /plan, /implement, /orchestrate commands
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 688
- **Research**: [690_wire_lit_flag_commands/reports/01_wire-lit-commands.md]
- **Plan**: [690_wire_lit_flag_commands/plans/01_wire-lit-commands-plan.md]
- **Summary**: [690_wire_lit_flag_commands/summaries/01_wire-lit-commands-summary.md]

**Description**: Thread the LIT_FLAG through all four workflow commands. For each command (research.md, plan.md, implement.md, orchestrate.md): (1) Add --lit to the Options table documentation. (2) Add lit_flag extraction in STAGE 1.5 (PARSE FLAGS) following the --clean pattern. (3) Pass lit_flag={lit_flag} in the skill invocation args string (STAGE 2: DELEGATE). (4) Include lit_flag in multi-task dispatch skill args. Also sync extension core copies of these command files.

---

### 689. Add --lit context injection to skill preflight (researcher, planner, implementer)
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 688
- **Research**: [689_lit_context_injection_skill_preflight/reports/01_lit-context-injection.md]
- **Plan**: [689_lit_context_injection_skill_preflight/plans/01_lit-context-injection-plan.md]
- **Summary**: [689_lit_context_injection_skill_preflight/summaries/01_lit-context-injection-summary.md]

**Description**: Add literature context injection to skill-researcher, skill-planner, and skill-implementer preflight stages, mirroring the memory-retrieve pattern used by --clean. When lit_flag is true in the delegation context: (1) check if specs/literature/ directory exists, (2) if it exists, list files and read relevant content, (3) inject as <literature-context> block into the agent delegation prompt alongside existing <memory-context>. If specs/literature/ does not exist, silently skip (no error, no warning). The injection should happen in the same preflight stage where memory retrieval occurs (after GATE IN, before agent dispatch). Create a .claude/scripts/literature-retrieve.sh script following the memory-retrieve.sh pattern: accepts task description and task_type as args, scans specs/literature/ for matching files, returns formatted context block. Also update skill-orchestrate to thread lit_flag through its dispatch calls to research/plan/implement skills.

---

### 688. Add --lit flag to parse-command-args.sh
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [688_add_lit_flag_parse_command_args/reports/01_lit-flag-parse.md]
- **Plan**: [688_add_lit_flag_parse_command_args/plans/01_lit-flag-parse-plan.md]
- **Summary**: [688_add_lit_flag_parse_command_args/summaries/01_lit-flag-parse-summary.md]

**Description**: Add LIT_FLAG variable to .claude/scripts/parse-command-args.sh. Parse --lit from remaining args (same pattern as --clean, --exploit, --explore). Export LIT_FLAG ("true" or "false"). Strip --lit from FOCUS_PROMPT in the sed cleanup chain. Update the export line to include LIT_FLAG. Also sync the extension core copy at .claude/extensions/core/scripts/parse-command-args.sh.

---

### 687. Create agent-level PR prohibition rule
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [687_agent_pr_prohibition_rule/reports/01_pr-prohibition-research.md]
- **Plan**: [687_agent_pr_prohibition_rule/plans/01_pr-prohibition-plan.md]
- **Summary**: [687_agent_pr_prohibition_rule/summaries/01_pr-prohibition-summary.md]

**Description**: Create .claude/rules/pr-prohibition.md (path pattern: **/*) that explicitly forbids all agents from: (1) creating PRs via gh pr create or glab mr create, (2) pushing to remote repositories via git push, (3) invoking the /merge command autonomously. The rule directs that only the user-invoked /pr command may submit PRs, and only after explicit user approval via AskUserQuestion. This is the documentation layer that instructs agents at the prompt level.

---

### 686. Add user approval gate to /merge command
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [686_merge_command_approval_gate/reports/01_merge-approval-research.md]
- **Plan**: [686_merge_command_approval_gate/plans/01_merge-approval-plan.md]
- **Summary**: [686_merge_command_approval_gate/summaries/01_merge-approval-summary.md]

**Description**: Add an AskUserQuestion confirmation step to .claude/commands/merge.md between STEP 3 (validate branch) and STEP 4 (push). Present the branch name, target branch, draft status, and a summary of commits for user review before proceeding with push and PR creation. Match the approval pattern used by the cslib /pr command (lines 792-803). Also add a prohibition note in the command header documentation stating that agents must never invoke /merge autonomously — it is a user-only command. Update the extension core copy at .claude/extensions/core/commands/merge.md to match.

---

### 685. Restrict Bash(git:*) permissions to exclude git push
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [685_restrict_git_push_permissions/reports/01_git-permissions-research.md]
- **Plan**: [685_restrict_git_push_permissions/plans/01_git-permissions-plan.md]
- **Summary**: [685_restrict_git_push_permissions/summaries/01_git-permissions-summary.md]

**Description**: Replace the blanket Bash(git:*) permission in .claude/settings.json with granular git operation entries that exclude git push. New entries: Bash(git status*), Bash(git diff*), Bash(git add*), Bash(git commit*), Bash(git log*), Bash(git branch*), Bash(git checkout*), Bash(git stash*), Bash(git fetch*), Bash(git rebase*), Bash(git merge*), Bash(git remote*), Bash(git rev-parse*), Bash(git show*), Bash(git blame*), Bash(git tag*), Bash(git cherry-pick*), Bash(git clean*), Bash(git reset*). This ensures any git push triggers a permission prompt requiring user approval. Do NOT modify the cslib project settings.json — the user will reload the agent system there separately.

---

### 684. Add PreToolUse hook to block PR/push operations
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [684_pretooluse_hook_pr_block/reports/01_pretooluse-hook-research.md]
- **Plan**: [684_pretooluse_hook_pr_block/plans/01_pretooluse-hook-plan.md]
- **Summary**: [684_pretooluse_hook_pr_block/summaries/01_pretooluse-hook-summary.md]

**Description**: Add a PreToolUse hook in .claude/settings.json that intercepts any Bash tool call and checks if the command contains gh pr create, glab mr create, or git push. If detected, return permissionDecision: deny with a message explaining that PR submission requires the /pr command with explicit user approval. The hook should use a matcher of Bash and inspect CLAUDE_TOOL_INPUT for the command field. This is the hardest enforcement layer since it operates at the tool-call level before execution and cannot be bypassed by agent prompt instructions. Create the hook script at .claude/hooks/block-pr-submission.sh for testability and maintainability rather than inlining the logic in settings.json. Do NOT modify the cslib project settings.json.

---

### 683. Cslib manifest keyword overrides
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 682
- **Research**: [683_cslib_manifest_keyword_overrides/reports/01_cslib-keyword-overrides.md]
- **Plan**: [683_cslib_manifest_keyword_overrides/plans/01_cslib-keyword-overrides.md]
- **Summary**: [683_cslib_manifest_keyword_overrides/summaries/03_execution-summary.md]

**Description**: Add keyword_overrides field to the cslib extension manifest.json. Map lean-related keywords (lean, lean4, mathlib, theorem, proof) to cslib task type with aliases: ["lean4"], and map PR-related keywords (pr, pull request, submit, upstream, branch, rebase, cherry-pick) to pr task type. This enables deterministic task type detection when the cslib extension is loaded, replacing agent judgment.

---

### 682. Extension keyword overrides task command
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [682_extension_keyword_overrides_task_command/reports/01_keyword-overrides-research.md]
- **Plan**: [682_extension_keyword_overrides_task_command/plans/02_keyword-overrides-plan.md]

**Description**: Add extension keyword_overrides support to the /task command (task.md step 4). After meta keyword check but before the hardcoded keyword table, scan loaded extension manifests for a keyword_overrides field. Schema: {"task_type": {"aliases": ["existing_type"], "keywords": ["word1", ...]}}. Aliases remap an existing keyword table result to the extension type. Keywords add new entries alongside the hardcoded table. Extension overrides take precedence over the hardcoded table so extensions can claim keywords from types they supersede.

---

### 681. Fix orchestrator final-completion TTS and tab opacity integration
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Terminal UI
- **Dependencies**: Task 679
- **Research**: [681_fix_orchestrator_final_tts/reports/01_orchestrator-tts-research.md]
- **Plan**: [681_fix_orchestrator_final_tts/plans/01_orchestrator-tts-plan.md]
- **Summary**: [681_fix_orchestrator_final_tts/summaries/01_implementation-summary.md]

**Description**: Fix orchestrator-postflight.sh Stage 8b to pass --quiet only for mid-orchestrate transitions (research->plan, plan->implement) and call lifecycle-notify.sh WITHOUT --quiet on final completion so TTS fires. Currently line 313 always passes --quiet with comment "this script is called mid-orchestrate where the orchestrator itself fires the final TTS on true completion" but no such final TTS code exists. The fix requires: (1) orchestrator-postflight.sh must know whether this is a mid-orchestrate call or final completion — add an argument or env var from the caller, (2) for final completion (implement postflight in non-orchestrate mode, or orchestrate final phase), call lifecycle-notify.sh without --quiet, (3) clear workflow-active marker before final Stop so claude-stop-notify.sh fires needs_input tab color + TTS, (4) verify dim-to-bright tab color transitions work correctly during orchestrate cycles (dim for in-progress, bright for completed, needs_input for awaiting user). Files: .claude/scripts/orchestrator-postflight.sh, .claude/scripts/lifecycle-notify.sh, .claude/hooks/claude-stop-notify.sh (workflow-active marker cleanup).

---

### 680. Fix Stop hook to fire TTS when user attention is needed
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Terminal UI
- **Dependencies**: Task 679
- **Research**: [680_fix_stop_hook_tts/reports/01_stop-hook-tts-research.md]
- **Plan**: [680_fix_stop_hook_tts/plans/01_stop-hook-tts-plan.md]
- **Summary**: [680_fix_stop_hook_tts/summaries/01_implementation-summary.md]

**Description**: Modify claude-stop-notify.sh to call tts-notify.sh when no workflow-active marker exists (= agent halted, user must act). When workflow-active marker IS present (mid-orchestrate pause), skip TTS so tab stays dim with no announcement. Add cooldown dedup to prevent rapid stop/start from spamming TTS. The current claude-stop-notify.sh (line 59) explicitly skips TTS with comment "no TTS for non-lifecycle stops" — this is the root cause of TTS never firing on /implement, /todo, /orchestrate completion. Files: .claude/hooks/claude-stop-notify.sh, .claude/hooks/tts-notify.sh (verify cooldown mechanism). Also harmonize with the global ~/.config/.claude/hooks/tts-notify.sh which does fire TTS on Stop but lacks the workflow-active marker pattern.

---

### 679. Research June 2026 TTS best practices for Claude Code hooks
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Terminal UI
- **Dependencies**: None
- **Research**: [679_research_tts_best_practices/reports/01_tts-best-practices.md]
- **Plan**: [679_research_tts_best_practices/plans/01_tts-research-plan.md]

**Description**: Web research on current Claude Code hook patterns for TTS/audio notifications as of June 2026. Compare with the existing Piper TTS + WezTerm tab color notification pipeline. Identify: (1) any new hook events beyond Stop/Notification/SubagentStop that could improve notification targeting, (2) best practices for deduplication and cooldown in multi-agent workflows, (3) whether the Notification hook matcher "permission_prompt|elicitation_dialog" is still the correct set of actionable notification types, (4) integration patterns between TTS announcements and terminal tab visual indicators. Document findings for tasks 680 and 681.

---

### 678. Adaptive auto-escalation advisory (v2)
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669

**Description**: Implement churn detection that emits a 'consider --hard' warning when repeated deflection patterns are observed: 2+ plan revisions on a single task, 3+ implement dispatches with no phase completion, or analysis-only output in implementation phases. This is advisory only -- does not auto-escalate. v2 trajectory item. Research inputs: specs/669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md, specs/669_hard_mode_agent_system/reports/02_team-research.md.

---

### 677. Contract lint and testing strategy for hard-mode behavioral correctness
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669
- **Plan**: [677_contract_lint_testing_strategy/plans/01_contract-lint-plan.md]

**Description**: Design and implement a testing strategy for hard-mode behavioral correctness: contract lint rules that verify agents honor anti-analysis budgets, reference grounding requirements, and convergence policing thresholds. May include test harnesses that replay known deflection-prone prompts against hard-mode agents and check for contract violations. Research inputs: specs/669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md, specs/669_hard_mode_agent_system/reports/02_team-research.md.

---

### 676. Add hard-mode routing to cslib extension
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669
- **Plan**: [676_cslib_extension_hard_mode_variants/plans/01_cslib-hard-mode-plan.md]

**Description**: Add hard-mode routing to the cslib extension following the same pattern as lean4: routing_hard manifest entries, skill-cslib-research-hard, skill-cslib-implementation-hard, cslib hard agents with domain-specific H-technique overrides. Research inputs: specs/669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md, specs/669_hard_mode_agent_system/reports/02_team-research.md.

---

### 675. Add hard-mode routing to lean4 extension
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669

**Description**: Add hard-mode routing to the lean4 extension: routing_hard manifest entries, skill-lean-research-hard, skill-lean-implementation-hard, lean hard agents with H3 strict transcription mandate, H5 formal divergence audit, H8 lemma-to-source mapping, H9 sorry inventory. Research inputs: specs/669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md, specs/669_hard_mode_agent_system/reports/02_team-research.md.

---

### 674. Upgrade /pr command for task-integrated workflow
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 671, Task 672, Task 673
- **Research**: [674_upgrade_pr_command_task_integration/reports/01_pr-command-integration.md]
- **Plan**: [674_upgrade_pr_command_task_integration/plans/01_pr-command-plan.md]
- **Summary**: [674_upgrade_pr_command_task_integration/summaries/01_implementation-summary.md]

**Description**: Upgrade the existing /pr command (cslib extension) to integrate with the task lifecycle. When invoked as `/pr N`, load the [PR READY] task, read pr-description.md from task artifacts, run the full CI pipeline with interactive fix, present/edit the description based on the standard format, handle stacked PR base branch detection, submit via `gh pr create`, and transition task to [COMPLETED]. Key changes: (1) task-mode reads pr-description.md instead of generating from scratch; (2) supports stacked PRs by detecting base_branch from task metadata; (3) updates task status on successful submission; (4) removes redundant CI checklist from description body (real CI runs in the pipeline step, per leanprover/cslib PR #635 convention). Source: .claude/extensions/cslib/commands/pr.md (885 lines) — refine its task-mode path while preserving path-mode and description-mode. Also fix the hardcoded state.json path bug in STEP 2 (currently points at /home/benjamin/.config/nvim/specs/state.json instead of the target project specs/).

---

### 673. Add pr task type routing to cslib extension
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 671, Task 672
- **Research**: [673_pr_task_type_routing/reports/01_pr-task-type-routing.md]
- **Plan**: [673_pr_task_type_routing/plans/01_pr-task-type-plan.md]
- **Summary**: [673_pr_task_type_routing/summaries/01_implementation-summary.md]

**Description**: Add a `pr` task type to the cslib extension manifest routing (.claude/extensions/cslib/manifest.json). This task type represents PR preparation work (as distinct from code implementation). Research phase: analyze code changes on the PR branch, dependency graph of stacked PRs, and prior PR descriptions. Plan phase: outline the PR description structure, branch strategy (new branch from upstream/main vs reuse existing), stacked PR base detection. Implement phase: create or validate the feature branch, generate pr-description.md from the standard format template, run initial CI verification, and transition the task to [PR READY] instead of [COMPLETED]. Requires manifest.json routing entries (research/plan/implement for task_type pr), potentially a skill-pr-implementation or reuse of cslib-implementation-agent with PR-specific behavior, and context injection for PR format standards from task 672.

---

### 672. Standardize CSLib PR description format
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [672_pr_description_format_standard/reports/01_pr-description-format.md]
- **Plan**: [672_pr_description_format_standard/plans/01_pr-description-format-plan.md]
- **Summary**: [672_pr_description_format_standard/summaries/01_implementation-summary.md]

**Description**: Create a canonical PR description format file in the cslib extension context (.claude/extensions/cslib/context/project/cslib/standards/ alongside pr-conventions.md), based on the leanprover/cslib PR #635/#637 pattern and the 6 existing pr-description.md files in the cslib project specs/. The format should define required and optional sections: Title (conventional commit format), Summary (2-4 sentences), Context/Motivation (Zulip links, stacked PR info, literature references), File-by-file change summary (### per file with bullets), Dependencies (stacked on #NNN), AI Disclosure (standardized boilerplate, always last), and optional design rationale sections. Key insight from PR #635: no CI checklist in the body (CI is verified in the pipeline, not claimed in the description). Add the file to index-entries.json so it is loaded for pr-type tasks, and update pr-conventions.md to reference the new format file instead of its outdated inline template.

---

### 671. Add [PR READY] status to task lifecycle
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [671_pr_ready_status_lifecycle/reports/01_pr-ready-status.md]
- **Plan**: [671_pr_ready_status_lifecycle/plans/01_pr-ready-status-plan.md]
- **Summary**: [671_pr_ready_status_lifecycle/summaries/01_implementation-summary.md]

**Description**: Add [PR READY] as a new non-terminal task status in the task lifecycle, gating between [IMPLEMENTING] and the /pr submission step. Changes needed (both live copies and extension sources per the sync convention): (1) Update .claude/rules/state-management.md and extensions/core/rules/state-management.md status transition documentation to include [PR READY] (state.json value: pr_ready) and its transitions ([IMPLEMENTING] -> [PR READY] for pr tasks, [PR READY] -> [COMPLETED] after /pr submission, [PR READY] -> [IMPLEMENTING] if issues found). (2) Update .claude/scripts/generate-todo.sh and extensions/core copy to render [PR READY]. (3) Update .claude/scripts/update-task-status.sh and extensions/core copy to accept the new status. (4) Update CLAUDE.md merge-source Status Markers section. (5) Verify generate-todo.sh correctly renders [PR READY] tasks in TODO.md. [PR READY] is NOT terminal.

---

### 670. Fix artifact counter system
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [670_fix_artifact_counter_system/reports/01_artifact-counter-analysis.md]
- **Plan**: [670_fix_artifact_counter_system/plans/02_fix-artifact-counter.md]

**Description**: Fix 4 bugs in the artifact counter system (next_artifact_number): (1) Revision does not increment counter — causes collisions when multiple plan revisions share the same number, (2) No collision detection when computed artifact number matches existing files, (3) Counter drift for legacy tasks that predate the unified numbering, (4) plan_version vs artifact sequence number confusion in filenames. Root cause observed during BimodalLogic task 273 (21 plan versions). Fix requires ~80 lines across 5-7 skill files.

---

### 669. Add hard-mode routing (--hard) with hard-mode skills and agents for very complex tasks
- **Effort**: 8-12 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**:
  - [669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md]
  - [669_hard_mode_agent_system/reports/02_team-research.md]
- **Plan**: [669_hard_mode_agent_system/plans/02_hard-mode-implementation.md]

**Description**: Create hard-mode variants of the agent system for very complex, deflection-prone tasks (e.g., deep Lean formalization): route --hard in /implement, /research, /plan, /orchestrate to hard-mode skills (skill-lean-implementation-hard, skill-orchestrate-hard, skill-planner-hard, skill-{domain}-research-hard) calling hard-mode agents. Hard mode encodes: per-phase dispatch (one bounded milestone per agent run), anti-analysis prompt contracts (read budgets, forbidden conclusions, counterexample bar for defect claims), prior-art transcription mandates with PDF-level citation, adversarial verification of research reports, divergence-audit trigger after repeated deflections (churn counters in loop guard), territory contracts for parallel dispatch, roadmap handoffs with incremental commit discipline, and hard-mode plan format (phases sized for single runs, postmortem constraints, lemma-to-source mapping, preserved-assets accounting). See report 01 for the full methodology distilled from the BimodalLogic task-273 session, measured outcomes, and a 7-step implementation breakdown.

---

### 668. Add default_task_type support to task creation pipeline
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Add a default_task_type field to state.json that projects can set to override the hardcoded keyword table in task.md step 4. When default_task_type is present, task.md uses it as the task type for all new tasks except those matching meta keywords (meta/agent/command/skill), which always override to meta since they modify .claude/ itself. This fixes the problem where CSLib tasks get lean4 or formal instead of cslib because the keyword table matches proof/theorem/lean/logic keywords before the cslib extension routing is consulted. Changes: (1) Modify task.md step 4 to read default_task_type from state.json via jq, use it as default when set, only allow meta keywords to override. (2) Sync extension copy at extensions/core/commands/task.md. (3) Update state-management-schema.md to document the new field. (4) Document in CLAUDE.md state.json schema section.

---

### 667. Create cslib /pr command
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663

**Description**: Create a /pr command for the cslib extension that accepts a task number, path (file or directory), or description to cherry-pick elements from main branch onto a feature branch, clean up code to CSLib quality standards, run the full CI pipeline (lake build, lake exe checkInitImports, lake lint, lake exe lint-style, lake shake --add-public --keep-implied --keep-prefix, lake exe mk_all --module, lake test), submit PR with user approval (conventional commit title: feat/fix/doc/style/refactor/test/chore/perf, AI disclosure in description), and merge back to main with user approval. Deliverables: command file at .claude/extensions/cslib/commands/pr.md, manifest.json provides.commands update, and optionally a dedicated skill-cslib-pr skill if complexity warrants separation.

---

### 666. Create cslib context and rules
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663

**Description**: Create rules/cslib.md (path pattern: **/*.lean for CSLib project) and context files under context/project/cslib/ covering: domain/ (CONTRIBUTING standards, notation conventions, project organization), patterns/ (proof structure, module organization, reuse-first philosophy), standards/ (CI pipeline, PR conventions, conventional commits, mathlib style), tools/ (lake commands, linters, checkInitImports, mk_all, lint-style, lake shake). CSLib-specific encoding: alpha equivalence notation, LTS transitions, reduction arrows from NOTATION.md. Working groups model and AI usage policy from CONTRIBUTING.md. Additionally, incorporate citation conventions from /home/benjamin/Projects/cslib/.claude/context/standards/citation-conventions.md as a new context file at context/project/cslib/standards/citation-conventions.md — this covers BibKey format (CamelCase, e.g. Blackburn2001), the references.bib workflow, canonical citation display format in module docstrings, and legacy pattern conversion rules.

---

### 665. Create cslib skills
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663

**Description**: Create skill-cslib-research/SKILL.md and skill-cslib-implementation/SKILL.md at .claude/extensions/cslib/skills/. Research skill delegates to cslib-research-agent with tools: lean-lsp MCP (inherited via lean dependency), WebSearch, WebFetch, Read, Bash. Implementation skill delegates to cslib-implementation-agent with tools: Read, Write, Edit, Bash (lake build, lake test, lake lint, lake exe checkInitImports, lake exe lint-style, lake shake). Both skills follow thin-wrapper pattern delegating to their respective agents.

---

### 664. Create cslib agents
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663

**Description**: Create cslib-research-agent.md (model: opus) and cslib-implementation-agent.md (model: sonnet) at .claude/extensions/cslib/agents/. Research agent: inherits lean-lsp MCP tools via lean dependency, focuses on CSLib-specific formalization patterns, mathlib API discovery, typeclass-based abstraction. Implementation agent: CI verification pipeline (lake test, lake exe checkInitImports, lake lint, lake exe lint-style, lake shake --add-public --keep-implied --keep-prefix), Cslib.Init import enforcement, mathlib style compliance, proof readability over golfing.

---

### 663. Create cslib extension scaffold
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Create the cslib extension scaffold at .claude/extensions/cslib/ modeled after the lean extension. Includes: manifest.json (task_type: "cslib", dependencies: ["core", "lean"], provides agents/skills/rules/context, routing table for research/plan/implement, no mcp_servers since lean-lsp inherited via lean dependency), EXTENSION.md (CLAUDE.md merge content for cslib section), README.md (extension documentation), index-entries.json (context discovery entries for cslib agents/task_types), and directory structure (agents/, skills/, commands/, rules/, context/project/cslib/{domain,patterns,standards,tools}/).

---

### 662. Wire postflight lifecycle notifications end-to-end
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Topic**: Terminal UI
- **Dependencies**: Task 661

**Description**: Wire lifecycle-notify.sh into the postflight pipeline for both standalone and orchestrate flows. Update orchestrator-postflight.sh to pass --quiet for mid-orchestrate phase completions (dim color change only, no TTS). Wire standalone command postflight (skill-base.sh) to call lifecycle-notify.sh on completion (with TTS). Ensure workflow-active marker cleanup so Stop hook fires needs_input at the right time. The dim/bright color distinction in wezterm.lua already exists — dim bg+fg for in-progress states (researching/planning/implementing), bright bg+fg for completed states (researched/planned/completed). Mid-orchestrate transitions should use the in-progress color of the NEXT phase (e.g., research done -> set planning dim color). Final completion or standalone completion should use the bright completed color + TTS announcement. Test: /research N standalone (bright researched + TTS), /orchestrate N multi-phase (dim color transitions, bright + TTS only at final stop).

---

### 661. Fix hook regexes and create lifecycle-notify.sh
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Topic**: Terminal UI
- **Dependencies**: None
- **Research**: [661_fix_hook_regexes_lifecycle_notify/reports/01_hook-regex-lifecycle.md]
- **Plan**: [661_fix_hook_regexes_lifecycle_notify/plans/01_hook-regex-lifecycle.md]

**Description**: Three fixes: (1) Add orchestrate to wezterm-task-number.sh Tier 1a regex alternation so /orchestrate N sets TASK_NUMBER correctly. (2) Add orchestrate to wezterm-preflight-status.sh Tier 1 matchers with appropriate initial status mapping (orchestrate starts with researching since it begins with research phase). (3) Create the missing .claude/scripts/lifecycle-notify.sh bridge script that orchestrator-postflight.sh already references at line 306. The script should accept a status argument (researched/planned/completed/etc.) and an optional --quiet flag. Normal mode: call wezterm-notify.sh to update tab color AND tts-notify.sh --lifecycle for TTS announcement. Quiet mode (--quiet): call wezterm-notify.sh only (no TTS) — used for mid-orchestrate phase transitions where the user does not need to be alerted.

---

### 660. Add preflight status updates to skill-orchestrate state handlers
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [660_orchestrate_preflight_status_updates/reports/01_preflight-analysis.md]
- **Plan**: [660_orchestrate_preflight_status_updates/plans/01_preflight-plan.md]
- **Summary**: [660_orchestrate_preflight_status_updates/summaries/01_preflight-summary.md]

**Description**: skill-orchestrate dispatches agents without calling update-task-status.sh preflight first. The individual skills (skill-researcher Stage 2, skill-planner Stage 2, skill-implementer Stage 2) all call preflight before spawning their agent, which sets task status to the in-progress variant (researching/planning/implementing) and — for implement — updates the plan file top-level Status to [IMPLEMENTING] via update-plan-status.sh. Without these preflight calls, orchestrated tasks stay at their prior status throughout execution and plan files never show [IMPLEMENTING]. Fix: (1) Add preflight calls in skill-orchestrate Stage 4 state handlers before each dispatch — research dispatch should call preflight:research, plan dispatch should call preflight:plan, implement dispatch should call preflight:implement. (2) Do the same in multi-task mode Stage MT-4 before each parallel dispatch batch. (3) Verify that update-plan-status.sh correctly transitions plan Status and that phase markers ([NOT STARTED] -> [IN PROGRESS] -> [COMPLETED]) are updated by the implementation agent during execution. The phase markers are the agents responsibility (general-implementation-agent Stage 4A/4D), but confirm the orchestrator dispatch prompt provides sufficient context for the agent to locate and edit the plan file.

---

### 659. Add phase containment for orchestrator-dispatched agents
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [659_orchestrator_phase_containment/reports/01_phase-containment.md]
- **Plan**: [659_orchestrator_phase_containment/plans/01_phase-containment.md]
- **Summary**: [659_orchestrator_phase_containment/summaries/01_phase-containment-summary.md]

**Description**: Add a phase_constraint field to the delegation context that skill-orchestrate passes when dispatching agents. When present, agents must confine their work to the assigned phase (research, plan, or implement) and must not spawn child agents for other lifecycle phases. Agents can note recommendations (e.g. implementation appears trivial) in the .orchestrator-handoff.json for the orchestrator to act on, but cannot execute cross-phase work themselves. Update agent definitions and dispatch-agent-spec.md to enforce this constraint. This prevents the pattern where a research agent spawns its own implementation sub-agent, bypassing the orchestrator state machine, planning phase, and standard artifact creation.

---

### 658. Integrate shared postflight into skill-orchestrate
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 657
- **Research**: [658_integrate_shared_postflight_orchestrate/reports/01_integration-research.md]
- **Plan**: [658_integrate_shared_postflight_orchestrate/plans/01_integration-plan.md]
- **Summary**: [658_integrate_shared_postflight_orchestrate/summaries/01_integrate-postflight-summary.md]

**Description**: Replace skill-orchestrate Stage 5 lightweight artifact linking (the inline skill_postflight_update/skill_link_artifacts calls) with calls to the shared orchestrator-postflight.sh script from Task 657. Update both single-task mode (Stage 5 handoff reading) and multi-task mode (Stage MT-4 per-task postflight). Ensure the orchestrator reads .return-meta.json (which agents already write) in addition to .orchestrator-handoff.json, so artifact metadata is reliably available. Update architecture docs (handoff-schema.md, dispatch-agent-spec.md, orchestrate-state-machine.md) to reflect the unified postflight path. Verify that orchestrated tasks produce identical artifact entries in state.json and TODO.md as tasks run via individual /research, /plan, /implement commands.

---

### 657. Create shared orchestrator-postflight.sh script
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [657_create_shared_orchestrator_postflight/reports/01_postflight-extraction.md]
- **Plan**: [657_create_shared_orchestrator_postflight/plans/01_postflight-script.md]
- **Summary**: [657_create_shared_orchestrator_postflight/summaries/01_postflight-script-summary.md]

**Description**: Extract the duplicated postflight logic from skill-researcher (Stages 6-9), skill-planner (Stages 6-9), and skill-implementer (Stages 6-10) into a shared .claude/scripts/orchestrator-postflight.sh script. The script should handle: (1) reading .return-meta.json metadata, (2) artifact validation via validate-artifact.sh, (3) status update via update-task-status.sh, (4) next_artifact_number incrementing (research only), (5) artifact linking to state.json via two-step jq pattern (Issue #1132 safe), (6) memory candidate propagation with append semantics, (7) generate-todo.sh regeneration, (8) lifecycle TTS notification, (9) cleanup of marker and metadata files. Parameterize by operation type (research/plan/implement) to handle the differences (e.g. only research increments artifact number, implement has completion_summary and roadmap_items). Refactor the three individual skills to call this shared script instead of inline postflight logic. Preserve all existing behavior including the jq escaping workarounds.

---

### 656. Add topic assignment to commands with missing or partial coverage
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 654

**Description**: Add topic assignment to 6 task creation points that currently have missing or incomplete topic handling, using the shared topic-assignment-pattern.md and manage-topics.sh:

1. **skill-fix-it/SKILL.md** (PARTIAL): Keep existing auto-inference heuristic as a suggestion, but add user confirmation via the shared pattern suggest mode. User can accept, override, or skip.
2. **commands/review.md** (PARTIAL): Same as fix-it — auto-inference as suggestion + confirmation picker. Also add active_topics array update when new topics are created.
3. **skills/skill-project-overview/SKILL.md** (MISSING): Add topic picker call using shared pattern interactive mode.
4. **skills/skill-spawn/SKILL.md** (inherit, no fallback): Keep parent inheritance as primary, add fallback to shared pattern interactive mode when parent has no topic.
5. **commands/task.md --expand** (inherit, no fallback): Same as spawn — inherit parent topic, fallback picker when parent is topicless.
6. **commands/task.md --review** (inherit, no fallback): Same as spawn — inherit parent topic, fallback picker when parent is topicless.

Also update extension copies (.claude/extensions/core/) to match all changes.

---

### 655. Refactor existing topic pickers to use shared utilities
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 654

**Description**: Replace duplicated inline topic picker logic in 4 existing commands/agents with references to the shared topic-assignment-pattern.md and calls to manage-topics.sh:

1. **commands/task.md** (Step 4.5): Replace ~50 lines of inline picker instructions with reference to shared pattern (interactive mode)
2. **agents/meta-builder-agent.md** (Stage 4.5 AssignTopic): Replace ~60 lines of batch picker instructions with reference to shared pattern (interactive mode, batch variant)
3. **commands/task.md** (--sync Step 6.5): Replace backfill picker with reference to shared pattern (interactive mode per-task)
4. **skills/skill-todo/SKILL.md** (Stage 2.5 TopicRevision): Replace revision picker with reference to shared pattern (interactive mode)

Each location becomes: "Follow the topic assignment pattern from @.claude/context/patterns/topic-assignment-pattern.md" plus manage-topics.sh calls for state updates. Also update extension copies (.claude/extensions/core/) to match.

Net reduction: ~200 lines of duplicated picker instructions replaced by pattern references.

---

### 654. Create shared topic management utilities (manage-topics.sh + pattern doc)
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Plan**: [654_create_topic_management_utilities/plans/01_topic-management-plan.md]

**Description**: Create two shared topic management artifacts to replace ~200 lines of duplicated topic picker logic across commands:

1. **manage-topics.sh** script with subcommands:
   - `list`: Output active_topics from state.json as newline-delimited list
   - `add TOPIC`: Add a new topic to the active_topics array (idempotent)
   - `set TASK_NUM TOPIC`: Set the topic field on a task entry in state.json
   - `validate TOPIC`: Check if topic exists in active_topics (exit 0/1)
   Uses flock for write safety consistent with existing state.json write patterns.

2. **topic-assignment-pattern.md** shared context pattern document describing:
   - The canonical AskUserQuestion flow (read active_topics, build picker options, handle New topic/Skip responses)
   - Three assignment modes: interactive (full picker), inherit (parent topic with fallback picker), suggest (auto-inferred topic pre-selected, user can override)
   - State update instructions (call manage-topics.sh for mechanical operations)
   - Commands reference this pattern instead of inlining 50 lines of picker instructions each.

This task creates the foundation; tasks 655 and 656 consume these utilities.

---

### 653. Update all task creation commands to state.json-first pattern
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 649
- **Research**: [653_update_task_creation_commands_state_first/reports/01_pipeline-audit.md]
- **Plan**: [653_update_task_creation_commands_state_first/plans/01_task-creation-state-first.md]
- **Summary**: [653_update_task_creation_commands_state_first/summaries/01_task-creation-migration-summary.md]

**Description**: Update all task creation commands and agents to follow the state.json-first pattern: write to state.json, then call generate-todo.sh for regeneration. Currently 8 HIGH-priority writers create entries directly in TODO.md, which generate-todo.sh will silently overwrite. Files to update: (1) commands/task.md — Create, Recover, Followup, Expand, Sync, Abandon modes: replace all TODO.md Edit/sed operations with state.json updates + generate-todo.sh call. (2) commands/review.md — task creation and goal line: add active_goal field to state.json schema, replace TODO.md Edit with state.json update + generate-todo.sh. (3) skill-spawn/SKILL.md — child task creation, parent status/deps updates: replace 3 Edit operations with state.json writes + generate-todo.sh. (4) skill-fix-it/SKILL.md — fix-it task creation: replace TODO.md prepend with state.json write + generate-todo.sh. (5) skill-project-overview/SKILL.md — task creation + link-artifact-todo call: replace with state.json write + generate-todo.sh. (6) agents/meta-builder-agent.md — batch task creation: replace batch Edit insertion with state.json writes + generate-todo.sh. Also update archive-task.sh (Python entry removal) and vault-operation.sh (sed renumber/comment) to use generate-todo.sh instead of direct TODO.md manipulation.

---

### 652. Post-validation cleanup: remove obsolete scripts after logging review
- **Effort**: 1 hour
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 649, Task 651, Task 653

**Description**: After ~1 week of the new pipeline running, review logs to verify the new generate-todo.sh pipeline is working reliably. Check that: (1) no deprecation-logged old code paths are being hit, (2) TODO.md regeneration succeeds consistently, (3) no state.json/TODO.md sync drift. Then remove: link-artifact-todo.sh (fully replaced by state.json + regeneration), old TODO.md awk/sed manipulation code from update-task-status.sh, dead functions from skill-base.sh, any transitional compatibility shims. Clean up deprecation logging. Mark as deferred until validation period passes.

---

### 651. Update rules and documentation for new state.json-first architecture
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 649, Task 653
- **Research**: [651_update_rules_and_documentation/reports/01_docs-update-research.md]
- **Plan**: [651_update_rules_and_documentation/plans/01_docs-rules-update.md]
- **Summary**: [651_update_rules_and_documentation/summaries/01_docs-rules-update-summary.md]

**Description**: Update rules and documentation for new state.json-first architecture. Remove Two-Phase Update Pattern from state-management.md (no longer needed). Update CLAUDE.md agent system section. Update skill-status-sync to reference new pipeline (remove all Edit-TODO.md instructions from K1-K3). Remove redundant TODO.md Edit instructions from extension skills: skill-nix-implementation (K4-K5), skill-neovim-implementation (K6-K7), skill-nix-research (K8), skill-neovim-research (K9). Remove TODO.md description Edit from skill-reviser (K10). Update skill-todo to use generate-todo.sh instead of Edit-based entry removal (K17-K18) and sed-based vault renumber/comment (K19-K20). Update archive-task.sh to call generate-todo.sh instead of Python entry removal. Update commands/implement.md to remove defensive TODO.md status correction (C10-C11). Update artifact-formats.md if linking format changed. Update workflow-diagrams if they reference old dual-write flow. Ensure all documentation consistently describes the new flow: command -> state.json update -> generate-todo.sh -> TODO.md regenerated.

---

### 650. Create update-phase-status.sh for phase-level plan tracking
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [650_create_update_phase_status_script/reports/01_phase-status-research.md]
- **Plan**: [650_create_update_phase_status_script/plans/01_phase-status-script.md]
- **Summary**: [650_create_update_phase_status_script/summaries/01_phase-status-summary.md]

**Description**: Create update-phase-status.sh script for phase-level status tracking in plan files. Updates individual phase markers ([NOT STARTED] -> [IN PROGRESS] -> [COMPLETED]) as implementation progresses through each phase. Called by implementation agents at each phase boundary for real-time oversight. Keeps existing update-plan-status.sh for plan-level status (header). Integrates with skill-implementer and general-implementation-agent so phases are marked as they execute. Add logging of phase transitions for oversight.

---

### 649. Simplify state update pipeline to state.json-only with TODO.md regeneration
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 648
- **Research**: [649_simplify_state_update_pipeline/reports/01_pipeline-simplification-research.md]
- **Plan**: [649_simplify_state_update_pipeline/plans/01_pipeline-simplification.md]
- **Summary**: [649_simplify_state_update_pipeline/summaries/01_pipeline-simplification-summary.md]

**Description**: Refactor update-task-status.sh to only update state.json + plan file status + call generate-todo.sh for regeneration. Remove all TODO.md awk/sed text surgery code (Phases 2 and 3). Simplify postflight-workflow.sh to update state.json artifacts only then call generate-todo.sh. Mark link-artifact-todo.sh as deprecated (artifacts tracked only in state.json, rendered by generate-todo.sh). Update skill-base.sh functions (skill_preflight_update, skill_postflight_update, skill_link_artifacts) to use simplified pipeline. Keep old code paths temporarily as logged fallbacks during transition period. Add deprecation logging so task 652 can verify old paths are unused.

---

### 648. Create generate-todo.sh to generate entire TODO.md from state.json
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 647
- **Research**: [648_create_generate_todo_script/reports/01_generate-todo-research.md]
- **Plan**: [648_create_generate_todo_script/plans/01_generate-todo-script.md]
- **Summary**: [648_create_generate_todo_script/summaries/01_generate-todo-summary.md]

**Description**: Create a single generate-todo.sh script that produces the entire TODO.md from state.json. Generates: YAML frontmatter (next_project_number), Task Order section (absorb/call existing generate-task-order.sh logic with Kahn wave computation and topic grouping), and Tasks section with all entries properly formatted (status markers, artifact links, descriptions, effort, dependencies). Terminal tasks (completed/abandoned/expanded) included in Tasks section for history but excluded from Task Order. Add lightweight logging (timestamp, operation, success/failure) to a log file for post-validation review.

---

### 647. Enrich state.json schema to be the single complete source of truth
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [647_enrich_state_json_schema/reports/01_team-research.md]
- **Plan**: [647_enrich_state_json_schema/plans/01_enrich-state-schema.md]
- **Summary**: [647_enrich_state_json_schema/summaries/01_enrichment-summary.md]

**Description**: Add title field to all task entries in state.json (currently only project_name slug exists; human-readable titles live only in TODO.md headings). Migrate full descriptions from TODO.md where missing or truncated in state.json. Ensure all metadata needed for TODO.md generation is present: effort, task_type, dependencies, artifacts, descriptions. This makes state.json self-sufficient as the sole source of truth for generating TODO.md.

---

### 646. Harden TODO.md status updates
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [646_harden_todo_status_updates/reports/01_harden-todo-status.md]
- **Plan**: [646_harden_todo_status_updates/plans/01_harden-todo-status.md]
- **Summary**: [646_harden_todo_status_updates/summaries/01_implementation-summary.md]

**Description**: Replace brittle sed pattern matching in update-task-status.sh phase 2 with robust awk/line-number approach that does not fail silently when status text format varies

---

### 645. Fix parallel write safety for state.json
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 643
- **Research**: [645_parallel_write_safety/reports/01_parallel-write-safety.md]
- **Plan**: [645_parallel_write_safety/plans/01_parallel-write-safety.md]
- **Summary**: [645_parallel_write_safety/summaries/01_parallel-write-safety-summary.md]

**Description**: Fix parallel write safety for state.json: replace shared specs/tmp/state.json temp path with mktemp unique per write, add flock mutex around state.json write operations in update-task-status.sh to prevent last-write-wins corruption when multiple agents write concurrently

---

### 644. Add reconciliation preflight to orchestrator
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 643
- **Research**: [644_reconciliation_preflight/reports/01_reconciliation-preflight.md]
- **Plan**: [644_reconciliation_preflight/plans/01_reconciliation-preflight.md]
- **Summary**: [644_reconciliation_preflight/summaries/01_reconciliation-preflight-summary.md]

**Description**: Add reconciliation preflight to orchestrator: at the start of each /orchestrate invocation scan task directories for artifacts that exist but whose status has not been promoted, replay missed postflight to provide self-healing for crashed agents missed handoffs and interrupted sessions

---

### 643. Eliminate dual postflight ownership
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 642
- **Research**: [643_eliminate_dual_postflight/reports/01_eliminate-dual-postflight.md]
- **Plan**: [643_eliminate_dual_postflight/plans/01_eliminate-dual-postflight.md]
- **Summary**: [643_eliminate_dual_postflight/summaries/01_implementation-summary.md]

**Description**: Eliminate dual postflight ownership: when orchestrator_mode=true the skill should SKIP its own skill_postflight_update and only write the handoff JSON so the orchestrator exclusively owns status transitions in state.json and TODO.md

---

### 642. Fix orchestrator_mode=false for research/plan dispatch
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [642_fix_orchestrator_mode_dispatch/reports/01_orchestrator-mode-dispatch.md]
- **Plan**: [642_fix_orchestrator_mode_dispatch/plans/01_fix-orchestrator-mode.md]
- **Summary**: [642_fix_orchestrator_mode_dispatch/summaries/01_implementation-summary.md]

**Description**: Fix orchestrator_mode=false for research/plan dispatch in skill-orchestrate/SKILL.md lines 934 and 959: change to orchestrator_mode true so handoff JSON is written and orchestrator postflight chain works for all phases not just implement

---

### 641. Fix meta-builder-agent topic assignment
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [641_meta_builder_topic_picker/reports/01_topic-picker-research.md]
- **Plan**: [641_meta_builder_topic_picker/plans/01_topic-picker-plan.md]
- **Summary**: [641_meta_builder_topic_picker/summaries/01_topic-picker-summary.md]

**Description**: Fix meta-builder-agent topic assignment: replace nonexistent keyword heuristic with interactive topic picker using active_topics + New topic option

---

### 640. Add topic revision stage to /todo skill
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [640_todo_topic_revision/reports/01_topic-revision-research.md]
- **Plan**: [640_todo_topic_revision/plans/01_topic-revision-plan.md]
- **Summary**: [640_todo_topic_revision/summaries/01_topic-revision-summary.md]

**Description**: Add topic revision stage to /todo skill and New topic option to /task --sync backfill

---

### 639. Fix /orchestrate TODO.md status sync and artifact linking
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Summary**: [639_fix_orchestrate_todo_sync/summaries/01_fix-summary.md]

**Description**: Replace bash function references in skill-orchestrate/SKILL.md with explicit, standalone bash commands that the orchestrator agent can execute directly via the Bash tool. The orchestrator currently updates state.json correctly but never updates TODO.md status markers or links artifacts because it treats skill_preflight_update, skill_postflight_update, and skill_link_artifact_from_handoff as pseudocode rather than callable functions (they require source skill-base.sh which agents don't run). Changes needed in both single-task (Stages 4-5) and multi-task (Stages MT-3/MT-4) sections.

---

### 638. Fix generate-task-order.sh to create Task Order section when missing
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Fix generate-task-order.sh to handle the case where ## Task Order doesn't exist in TODO.md. In --update-todo mode, if the ## Task Order section is not found, INSERT it before the first ## Tasks section instead of failing with a warning. This makes the script idempotent -- it creates the section on first run and replaces it on subsequent runs. Also verify the script generates clean output matching the BimodalLogic format (waves table + topic tree, no artifact links in task order entries).

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
