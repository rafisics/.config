---
next_project_number: 760
---

# TODO

## Task Order

*Updated 2026-06-23. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,758 | -- | literature, Terminal UI, Email Integration |

**Grouped by Topic** (indented = depends on parent):

### Literature

758 [PLANNED] — Refactor literature/zotero into unified literature system: (1) Gl

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 759. Fix implemented status leaking into state.json instead of completed
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [759_fix_implemented_status_leak/reports/01_status-leak-fix.md]
- **Plan**: [759_fix_implemented_status_leak/plans/01_status-leak-fix.md]
- **Summary**: [759_fix_implemented_status_leak/summaries/01_status-leak-fix-summary.md]

**Description**: Agent return value "implemented" leaks into state.json as a raw status instead of being normalized to "completed". Three fix sites: (1) skill-status-sync/SKILL.md line 164 maps implemented->[IMPLEMENTED] — should normalize to completed/[COMPLETED]; (2) generate-todo.sh has no explicit mapping for "implemented" — wildcard uppercases to IMPLEMENTED; (3) skill-orchestrate/SKILL.md line 703 writes status:"implemented" in partial-exit metadata — should write "completed". Extension mirrors (.claude/extensions/core/) need matching fixes.

---

### 758. Unified literature system
- **Status**: [PLANNED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: None
- **Research**:
  - [758_unified_literature_system/reports/01_infrastructure-audit.md]
  - [758_unified_literature_system/reports/02_agent-design-patterns.md]
  - [758_unified_literature_system/reports/03_storage-architecture.md]
  - [758_unified_literature_system/reports/04_extension-consolidation.md]
  - [758_unified_literature_system/reports/05_research-synthesis.md]
  - [758_unified_literature_system/reports/06_team-research.md]
  - [758_unified_literature_system/reports/07_literature-workflow-design.md]
- **Plan**: [758_unified_literature_system/plans/08_unified-literature-plan.md]

**Description**: Refactor literature/zotero into unified literature system: (1) Global Literature/ repo as single source of truth for segmented+indexed markdown, tracked by git; (2) Per-repo sub-index (specs/literature-index.json) declaring relevant sources; (3) Replace --lit/--zot context injection with a literature-agent that receives the sub-index and autonomously explores the global Literature/ corpus; (4) Consolidate literature+zotero extensions into one extension; (5) Design the literature-agent tool interface (search, read chunks, cross-reference)

---

### 757. Add summary field to skill_write_orchestrator_handoff artifacts
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task 756
- **Research**: [757_fix_handoff_artifact_summary/reports/01_handoff-summary-fix.md]
- **Summary**: [757_fix_handoff_artifact_summary/summaries/01_handoff-summary-fix-summary.md]

**Description**: In .claude/scripts/skill-base.sh line 436, skill_write_orchestrator_handoff() builds the artifacts JSON without a summary field (uses printf with only type and path). When orchestrate reads this handoff and calls skill_link_artifacts, the summary is empty, overwriting any good artifact data. Fix: (1) Add 10th parameter artifact_summary to the function signature, (2) Include summary in the artifacts JSON via jq instead of printf, (3) Update the usage comment at lines 384-386. Secondary fix: ensure callers (skill-implementer SKILL.md postflight) pass the artifact summary from .return-meta.json when calling this function.

---

### 756. Fix orchestrate Stage 5 to link artifacts via .return-meta.json fallback
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [756_fix_orchestrate_artifact_linking/reports/01_artifact-linking-fix.md]
- **Summary**: [756_fix_orchestrate_artifact_linking/summaries/01_artifact-linking-fix-summary.md]

**Description**: When /orchestrate dispatches research/plan/implement agents directly (bypassing skill layer), no .orchestrator-handoff.json is written. Stage 5 sees no handoff and skips artifact linking and status postflight entirely. Fix: when no handoff file exists in Stage 5, fall back to reading .return-meta.json from the task directory, extract status + artifact path/type/summary, then call skill_postflight_update and skill_link_artifacts. Affected file: .claude/skills/skill-orchestrate/SKILL.md (Stage 5 handoff reading, lines ~346-417). The if-branch for missing handoff should read .return-meta.json via skill_read_metadata and proceed with postflight + artifact linking instead of just logging an error and continuing.

---

### 755. Port /vet command-skill-agent triplet to cslib extension
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [755_port_vet_to_cslib_extension/reports/01_port-vet-research.md]
- **Plan**: [755_port_vet_to_cslib_extension/plans/01_port-vet-plan.md]

**Description**: Port /vet command-skill-agent triplet from cslib project to cslib extension. Tasks 270-271 in /home/benjamin/Projects/cslib/ created /vet as project-local files (.claude/commands/vet.md, .claude/skills/skill-cslib-vet/SKILL.md, .claude/agents/cslib-vet-agent.md) but never added them to the cslib extension. Port all three into /home/benjamin/.config/nvim/.claude/extensions/cslib/ (commands/, skills/, agents/ directories), register in manifest.json (agents, skills, commands arrays), and update EXTENSION.md + README.md. Critical requirement: the AskUserQuestion tool must be available to the skill (not the agent) for interactive violation selection during /vet execution -- verify the skill's allowed-tools includes AskUserQuestion and that the agent does NOT call it (agent writes findings to .vet-findings.json, skill reads findings and presents via AskUserQuestion). Also register cslib-vet-agent in the skill-agent mapping table and add /vet to the commands table in both EXTENSION.md and README.md.

---

### 754. Update cslib extension README.md to reflect all capabilities
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [754_update_cslib_extension_readme/reports/01_cslib-readme-update.md]
- **Plan**: [754_update_cslib_extension_readme/plans/01_cslib-readme-plan.md]
- **Summary**: [754_update_cslib_extension_readme/summaries/01_cslib-readme-summary.md]

**Description**: Update the cslib extension README.md to match the actual extension capabilities documented in EXTENSION.md and manifest.json. Currently README.md shows only 2 agents (actual: 6), 2 skills (actual: 7), says commands are "(none)" (actual: /pr), shows 1 rule (actual: 2), and omits hard-mode support, PR review workflow, and pr task type. Modeled after task 270 which updated the founder extension docs to match v3.0 capabilities. Update: (1) Architecture tree to show all agents (including hard-mode and pr-review), skills, /pr command, both rules. (2) Skill-Agent Mapping table to include all 7 skills. (3) Overview routing table to include pr task type. (4) Language Routing to include pr task type tools. (5) Add --hard mode section. (6) Add PR review workflow section. (7) Add Commands table showing /pr usage. (8) Bump manifest.json version if warranted.

---

### 753. Implement Zotero context injection (--zot flag)
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 751, Task 752
- **Research**: [753_implement_zotero_context_injection/reports/01_context-injection-research.md]
- **Plan**: [753_implement_zotero_context_injection/plans/01_context-injection-plan.md]
- **Summary**: [753_implement_zotero_context_injection/summaries/01_context-injection-summary.md]

**Description**: Implement the --zot flag for /research, /plan, and /implement that injects Zotero-sourced literature context into agent prompts via the per-repo local index. (1) Create zotero-retrieve.sh — reads the per-repo specs/zotero-index.json (not the global Zotero library), scores entries against task description using the improved scoring algorithm designed in task 748 (NOT the naive single-keyword-overlap approach from literature-retrieve.sh which routinely injects wrong papers), retrieves markdown chunks from Zotero child attachments for top-scoring entries within token budget, outputs <zotero-context> block. The local index is what makes this repo-aware: only citations linked to this project are considered. (2) Wire --zot flag into command-route-skill.sh alongside existing --lit flag. (3) Ensure composability: --zot and --lit are independent (--lit reads flat specs/literature/ directory, --zot reads from Zotero via local index). --clean suppresses memory but not --zot/--lit. Both can be used together. (4) Token budget enforcement (TOKEN_BUDGET=8000, MAX_FILES=10). For chunked documents, select relevant chunks rather than including all. (5) On-demand conversion trigger: if a linked citation lacks markdown chunks in Zotero, trigger conversion before retrieval.

---

### 752. Implement on-demand PDF-to-markdown conversion via Zotero
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 750, Task 751
- **Research**: [752_implement_ondemand_pdf_markdown_conversion/reports/01_pdf-conversion-research.md]
- **Plan**: [752_implement_ondemand_pdf_markdown_conversion/plans/01_pdf-conversion-plan.md]
- **Summary**: [752_implement_ondemand_pdf_markdown_conversion/summaries/01_pdf-conversion-summary.md]

**Description**: Implement the on-demand PDF-to-markdown conversion pipeline that stores chunks in Zotero as child attachments alongside the original PDF. (1) When a linked citation is needed (during --zot retrieval or explicit /zotero --convert KEY), check if markdown chunks already exist as child attachments on the Zotero item. (2) If not, resolve the PDF path from Zotero storage, convert using pdftotext with content-aware chunking (reuse logic from literature-chunk.sh), and store each chunk as a separate child attachment on the same Zotero parent item via zotero-cli-attach.sh, tagged with ordering metadata (chunk_01, chunk_02, etc.). This keeps all literature content in Zotero as the single source of truth. (3) Update the per-repo local index (specs/zotero-index.json) with has_markdown=true, chunk_count, and per-chunk token counts. (4) Support batch conversion: /zotero --convert-all to convert all linked citations lacking markdown. (5) Handle retrieval of chunked documents — reassemble chunks in order from child attachments, respecting token budget by selecting relevant chunks rather than always including all.

---

### 751. Implement Zotero search and local index management
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 749, Task 750
- **Research**: [751_implement_zotero_search_local_index/reports/01_search-index-research.md]
- **Plan**: [751_implement_zotero_search_local_index/plans/01_search-index-plan.md]
- **Summary**: [751_implement_zotero_search_local_index/summaries/01_search-index-summary.md]

**Description**: Implement the /zotero --search and local index management functionality. (1) /zotero --search 'QUERY' — search Zotero library via CLI wrapper scripts, present results with availability tags ([HAS MARKDOWN], [PDF ONLY], [NO PDF]), allow multi-select to link citations to local index. (2) /zotero --link KEY — add a Zotero citation key to specs/zotero-index.json, recording metadata (title, authors, year, keywords, has_markdown, token_count). (3) /zotero --unlink KEY — remove from local index. (4) /zotero --status — show local index health, linked citations count, markdown availability. (5) /zotero --task N — extract task description as search query (like literature --task N). The local index (specs/zotero-index.json) maps Zotero citation keys to per-project relevance data.

---

### 750. Implement Zotero CLI wrapper scripts
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 748, Task 749

**Description**: Create shell scripts that wrap the chosen Zotero CLI tool (from task 747) to provide a stable interface for the extension. Scripts: (1) zotero-cli-search.sh — search Zotero library by keyword, return JSON results with citation keys, titles, authors, years, PDF paths, attachment info. (2) zotero-cli-read.sh — read a specific item's metadata, notes, and child attachments by citation key. Must support listing child attachments (markdown chunks stored alongside PDFs). (3) zotero-cli-attach.sh — attach a file (converted markdown chunk) as a child attachment to a Zotero item, with ordering metadata in tags (e.g. chunk_01, chunk_02) so chunks can be retrieved in sequence. (4) zotero-cli-note.sh — create/update a note on a Zotero item. (5) zotero-cli-children.sh — list and retrieve child attachments for a parent item, filtering by type (markdown chunks vs other attachments), returning paths and ordering info. All scripts should handle authentication, provide JSON output, support offline SQLite fallback where possible, and include graceful degradation with setup instructions when the CLI tool is not installed. Follow the exit code contract pattern (0=success, 1=not configured, 2=no results).

---

### 749. Create Zotero extension skeleton
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 748

**Description**: Create the extension scaffold for the new 'zotero' extension at .claude/extensions/zotero/. Includes: manifest.json (with routing, dependencies on core/filetypes, provides block for commands/skills/scripts/agents), EXTENSION.md (CLAUDE.md merge source documenting the extension), commands/zotero.md (argument parsing and dispatch), skills/skill-zotero/SKILL.md (direct execution skill with mode handlers), agents/zotero-agent.md (documentation agent). Wire into the extension loader so it can be picked via the extension picker. Follow existing literature extension as template but adapted for the Zotero CLI-backed architecture from task 748 design.

---

### 748. Design Zotero extension architecture
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: Task 747
- **Research**: [748_design_zotero_extension_architecture/reports/01_zotero-extension-arch.md]

**Description**: Design the architecture for a new 'zotero' extension using a two-tier model: Zotero as the global literature source, per-repo local indices as relevance filters. Key design decisions: (1) Per-repo local index schema — specs/zotero-index.json maps Zotero citation keys to project-specific relevance, with fields for cached markdown availability, per-chunk token counts, keywords, and retrieval scoring metadata. The local index is what makes --zot repo-aware: each project tracks only the citations relevant to it. (2) Chunk storage in Zotero — when large PDFs are converted to markdown, the chunks are stored as child attachments in Zotero alongside the original PDF, with ordering metadata in attachment tags/notes. This keeps Zotero as the single source of truth for all literature content. (3) Context injection via --zot flag — parallel to --lit but index-driven: reads the per-repo local index, scores entries against task description, retrieves markdown chunks from Zotero for top-scoring entries within token budget. Contrast with current --lit which injects everything from a flat specs/literature/ directory with no per-repo filtering. (4) Retrieval scoring algorithm — the current --lit uses naive keyword-overlap scoring (literature-retrieve.sh lines 100-122, MIN_SCORE=1) which routinely injects wrong papers (e.g. matching 'logic' across unrelated domains). Design a better scoring approach for --zot: consider multi-field scoring (title, abstract, keywords, user-assigned tags), requiring minimum 2+ keyword matches, weighting domain-specific terms higher than generic ones, or leveraging Zotero tags/collections as relevance signals. (5) Coexistence strategy — --lit remains for flat-file use cases; --zot provides the Zotero-backed, index-filtered approach. They are independent and composable. (6) Command surface — /zotero command with subcommands (status, search, convert, link, unlink). (7) Script architecture — CLI wrapper layer, chunk management, retrieval pipeline. Reference the existing literature extension as architectural template. Depends on task 747 CLI tool evaluation results.

---

### 747. Evaluate Zotero CLI tools for shell-first integration
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: None
- **Research**: [747_evaluate_zotero_cli_tools/reports/01_zotero-cli-eval.md]
- **Plan**:
  - [747_evaluate_zotero_cli_tools/plans/01_zotero-cli-eval.md]
  - [747_evaluate_zotero_cli_tools/plans/01_zotero-cli-eval.md]
- **Summary**:
  - [747_evaluate_zotero_cli_tools/summaries/01_zotero-cli-eval-summary.md]
  - [747_evaluate_zotero_cli_tools/summaries/01_zotero-cli-eval-summary.md]

**Description**: Research and evaluate zotero-cli-cc (Agents365-ai) and 54yyyu/zotero-cli for use as the shell-first backend for a new Zotero extension. Key evaluation criteria: (1) Can they read/write attachments and notes on Zotero items? (2) Can converted markdown be stored as Zotero attachments or linked notes? (3) Offline SQLite access vs Web API modes — what operations work offline? (4) PDF access — can they resolve and read PDFs from Zotero storage? (5) JSON output format for agent consumption. (6) Authentication model (API keys, OAuth). (7) Search capabilities (keyword, full-text, tag-based). (8) Installation on NixOS (pip/pipx availability). (9) Child attachment hierarchy — can the CLI create and list child attachments under a parent Zotero item? This is critical for storing markdown chunks alongside PDFs as sibling attachments. Produce a comparison matrix and recommendation for which tool (or combination) to use.

---

### 746. Enforce plan checkbox tracking during implementation and orchestration
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**:
  - [746_enforce_plan_checkbox_tracking/reports/01_plan-checkbox-tracking.md]
  - [746_enforce_plan_checkbox_tracking/reports/01_plan-checkbox-tracking.md]
- **Plan**:
  - [746_enforce_plan_checkbox_tracking/plans/01_plan-checkbox-tracking.md]
  - [746_enforce_plan_checkbox_tracking/plans/01_plan-checkbox-tracking.md]
- **Summary**:
  - [746_enforce_plan_checkbox_tracking/summaries/01_plan-checkbox-tracking-summary.md]
  - [746_enforce_plan_checkbox_tracking/summaries/01_plan-checkbox-tracking-summary.md]

**Description**: Fix plan checkbox drift during /implement and /orchestrate by adding three enforcement mechanisms: (1) Strengthen the self-review gate in general-implementation-agent.md Stage 4D-ii — make it a hard requirement that any phase marked [COMPLETED] must have all - [ ] items checked off or annotated as deviations before proceeding. (2) Add a postflight plan-checkbox validation step in skill-implementer SKILL.md — after the agent finishes, compare completed work against unchecked plan items and auto-fix mismatches via Edit. (3) Extend the orchestrator handoff schema (.orchestrator-handoff.json) to include a subtasks_completed array (e.g. ["1.1", "1.2", "2.1"]) so the orchestrator has per-subtask visibility when dispatching successors. Files to modify: .claude/agents/general-implementation-agent.md, .claude/skills/skill-implementer/SKILL.md, .claude/skills/skill-orchestrate/SKILL.md, .claude/context/patterns/orchestrator-handoff.md (if exists)

---

### 745. Defer orchestrate commits until first implementation cycle
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**:
  - [745_defer_orchestrate_commits/reports/01_defer-commits.md]
  - [745_defer_orchestrate_commits/reports/01_defer-commits.md]
- **Plan**:
  - [745_defer_orchestrate_commits/plans/01_defer-commits-plan.md]
  - [745_defer_orchestrate_commits/plans/01_defer-commits-plan.md]
- **Summary**:
  - [745_defer_orchestrate_commits/summaries/01_defer-commits-summary.md]
  - [745_defer_orchestrate_commits/summaries/01_defer-commits-summary.md]

**Description**: Modify /orchestrate commit behavior: (1) In skill-orchestrate SKILL.md Stage 5, add a git commit after each implementation dispatch (status=implemented or partial with phases_completed>0), bundling all uncommitted artifacts from prior research/plan cycles. Skip commits for researched/planned statuses. (2) In orchestrate.md CHECKPOINT 3, make the final commit conditional — only commit if there are uncommitted changes (avoid empty/duplicate commits when per-implementation-cycle commits already captured everything). Files to modify: .claude/skills/skill-orchestrate/SKILL.md, .claude/commands/orchestrate.md

---

### 744. Include pr-description.md in feature branch during /pr workflow
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 743
- **Research**: [744_include_pr_description_in_feature_branch/reports/01_pr-description-copy.md]
- **Plan**: [744_include_pr_description_in_feature_branch/plans/01_pr-description-copy-plan.md]

**Description**: Modify the /pr command to copy pr-description.md from specs/{NNN}_{SLUG}/ into the cslib repo (e.g., as pr-description.md at repo root) after STEP 9 and before STEP 10. The file should be left unstaged (not git-added) so the user can review the full PR description alongside the code changes before pushing. This gives the user a convenient way to inspect the PR description in the context of the feature branch. Files to modify: .claude/extensions/cslib/commands/pr.md

---

### 743. Standardize AI Tools Used section across PR templates and agents
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [743_standardize_ai_tools_used_section/reports/01_ai-tools-standardization.md]
- **Plan**: [743_standardize_ai_tools_used_section/plans/01_ai-tools-plan.md]

**Description**: Fix inconsistent ## AI Tools Used section in PR description generation. Three files need changes: (1) cslib-implementation-agent.md -- replace the vague [describe what it did] placeholder with a reference to the canonical template in pr-description-format.md; (2) pr.md command -- change ## AI Disclosure heading to ## AI Tools Used in the Step 9 path/description template, and align text with the canonical format; (3) pr-description-format.md is already correct (canonical source, no changes needed). Files to modify: .claude/extensions/cslib/agents/cslib-implementation-agent.md, .claude/extensions/cslib/commands/pr.md

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
