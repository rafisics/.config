---
next_project_number: 727
---

# TODO

## Task Order

*Updated 2026-06-16. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,652,720,727,728 | -- | agent-system, Literature, Terminal UI, ... |

**Grouped by Topic** (indented = depends on parent):

### Agent System

652 [NOT STARTED] — After ~1 week of the new pipeline running, review logs to verify 

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

### Literature

720 [NOT STARTED] — Integration testing and verification of /cite command end-to-end.

### Uncategorized

727 [RESEARCHED] — Apply lessons from CSLib tasks 208-213 multi-task orchestration t
728 [RESEARCHED] — Add lint prevention rules to cslib extension agents. 7 rules cove

## Tasks

### 728. Cslib lint prevention rules
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: None

**Description**: Add lint prevention rules to cslib extension agents. 7 rules covering docBlame, defLemma, defsWithUnderscore, simpNF, unusedSectionVars, topNamespace, and dupNamespace. These environment linters are not in PR CI (only weekly cron) so agent-level enforcement is needed. Creates rules file, updates agent instructions, and adds targeted lint verification step.

---

### 727. Cslib orchestration lessons
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: None

**Description**: Apply lessons from CSLib tasks 208-213 multi-task orchestration to improve cslib extension agents, rules, and skills. Addresses: context exhaustion on large mechanical tasks, analysis paralysis, concurrent file conflicts, stale handoff files, and inaccurate error counts. Proposes lint-fix task type, anti-analysis rules, file-overlap wave assignment, write-first handoff pattern, and conflict matrix in planner.

---

### 726. Update pr review routing docs
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 722, Task 723, Task 724, Task 725

**Description**: Register the new pr task type routing for the core agent system (not CSLib-specific). Add routing entries so /research on pr tasks routes to skill-pr-review-research and /implement routes to skill-pr-review-implementation. Handle coexistence with CSLib extension pr routing (CSLib pr tasks use skill-cslib-research and skill-pr-implementation for PR submission workflow; core pr tasks from --review use the new review skills). Update CLAUDE.md routing tables, pr-prohibition.md to document the --review workflow, and command reference table to show /pr --review usage. Update skill-to-agent mapping tables.

---

### 725. Add pr ready push zulip
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 724
- **Research**: [725_add_pr_ready_push_zulip/reports/01_pr-ready-push-zulip.md]
- **Plan**: [725_add_pr_ready_push_zulip/plans/01_pr-ready-push-zulip.md]
- **Summary**: [725_add_pr_ready_push_zulip/summaries/01_pr-ready-push-zulip-summary.md]

**Description**: Extend /pr to handle PR READY tasks from the --review workflow. When invoked on a PR READY pr-type task: (1) push a single next commit (no squash, preserving the commit as a reference for PR comments), (2) seek explicit user approval via AskUserQuestion before pushing, (3) if task has zulip-response.md artifact, offer to send Zulip message using zulip-send CLI with parsed stream/subject from the Zulip source URL. Zulip URL parsing: https://org.zulipchat.com/#narrow/stream/123-general/topic/my.20topic extracts --stream "general" --subject "my topic" (.20 = URL-encoded space). Support both stream messages (zulip-send --stream S --subject T --message M) and piped content (cat zulip-response.md | zulip-send --stream S --subject T). Seek separate explicit approval for Zulip messages. Transition task to [COMPLETED] after all actions.

---

### 724. Create pr review implementation skill
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 723

**Description**: Create skill-pr-review-implementation that handles /implement on pr-type tasks created by /pr --review. The implementation agent should: implement the solution addressing PR review feedback based on the research report, compose pr-response.md (summary of changes for GitHub PR comment) and/or zulip-response.md (message for Zulip thread) in the task directory as appropriate based on which source types are present, and transition the task to [PR READY]. Response files should reference the specific comments being addressed. The zulip-response.md should contain the message text ready to pipe to zulip-send.

---

### 723. Create pr review research skill
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 722

**Description**: Create skill-pr-review-research that handles /research on pr-type tasks created by /pr --review. The research agent should: fetch PR comments from GitHub URLs via gh api (repos/{owner}/{repo}/pulls/{num}/comments and /reviews), fetch Zulip thread content from Zulip URLs, synthesize the discussion across all sources, and produce a research report summarizing review feedback, requested changes, and open questions. Support multiple rounds of research as new comments arrive. The skill should read the sources array from task metadata in state.json to know which URLs to fetch.

---

### 722. Add pr review flag
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Extend the /pr command (or create a core /pr command at .claude/commands/pr.md that coexists with the CSLib extension /pr) with a --review flag. When invoked as /pr --review, accept one or more arguments: GitHub PR URLs, Zulip chat URLs, and/or free-text descriptions. Create a task with task_type "pr" and store the provided URLs/descriptions as a "sources" array in the state.json task metadata. Each source entry should have {type: "github_pr" | "zulip_thread" | "description", url: "...", parsed: {...}} structure. Parse Zulip URLs (https://org.zulipchat.com/#narrow/stream/123-general/topic/my.20topic) to extract stream name and topic. Create the task directory and transition to [NOT STARTED]. Key design decisions during research: command location (core vs extension), source metadata schema, Zulip URL parsing utility.

---

### 721. Design targeted literature retrieval
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Literature
- **Dependencies**: None
- **Plan**: [721_design_targeted_literature_retrieval/plans/07_implementation-plan.md]
- **Summary**: [721_design_targeted_literature_retrieval/summaries/07_execution-summary.md]

**Description**: Research and design a targeted literature retrieval system to replace the current shallow keyword-overlap scoring in literature-retrieve.sh. The current --lit flag does keyword-based targeting (not blind bulk dump) but scoring is crude: bag-of-words overlap on keywords[] and summary fields, no content search, no semantic weighting. With 183 entries (many at 5000+ tokens) and an 8000 token budget, selection quality matters enormously. Benchmark current approach against: (1) Enhanced jq scoring with TF-IDF-like weighting, content preview fields in index, multi-field weighted scoring. (2) Agent-callable search tool where agents query the index and selectively read files instead of preflight bulk injection. (3) SQLite FTS5 as ephemeral query cache (task 710 deferred this at 183 entries, threshold ~500-1000). Test against real queries from existing tasks (e.g., task 201 IPL completeness). Key design question: should --lit remain preflight injection or become an agent-invocable search tool? Produce concrete recommendation with implementation plan.

---

### 720. Integration test cite command
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: Literature
- **Dependencies**: Task 719

**Description**: Integration testing and verification of /cite command end-to-end. Test with a task that has known citation claims in its artifacts. Verify: (1) cite-extract.sh correctly identifies citation patterns, (2) Literature/ index search returns relevant matches, (3) Zotero search integration works (graceful degradation if no library), (4) confidence scoring produces reasonable results, (5) AskUserQuestion multiSelect presents findings correctly, (6) task creation for accepted changes follows multi-task creation standard. Fix any issues found during testing.

---

### 719. Update literature manifest cite
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Literature
- **Dependencies**: Task 718

**Description**: Update literature extension manifest and documentation for /cite command. Files: (1) .claude/extensions/literature/manifest.json -- add cite command to provides.commands, skill-cite to provides.skills, cite-extract.sh to provides.scripts. (2) .claude/extensions/literature/EXTENSION.md -- add /cite section documenting workflow, arguments, and output format. (3) Core merge-sources/claudemd.md -- add /cite command row to command reference table. (4) Regenerate CLAUDE.md.

---

### 718. Create cite command file
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Literature
- **Dependencies**: Task 717

**Description**: Create cite.md command file at .claude/extensions/literature/commands/cite.md with argument parsing. Modes: /cite N (verify citations for task N), /cite "description text" (verify freeform text), /cite N --gaps (focus on finding missing citations), /cite N "focus" (task + focus text). Validates task exists in state.json, delegates to skill-cite. Follow same pattern as commands/literature.md for argument parsing and skill delegation.

---

### 717. Create skill cite verification
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Literature
- **Dependencies**: Task 716

**Description**: Create skill-cite direct execution skill at .claude/extensions/literature/skills/skill-cite/SKILL.md. Workflow: (1) read task artifacts (reports, plans) and description, (2) call cite-extract.sh to extract citation claims, (3) search Literature/ index and Zotero library (via zotero-search.sh) for matches to each claim, (4) score match confidence as confirmed/partial/unconfirmed/gap, (5) present findings via AskUserQuestion with multiSelect following multi-task creation standard (compare /fix-it pattern), (6) create tasks for accepted corrections, additions, and gap-fills. Direct execution skill like /fix-it -- no separate agent needed.

---

### 716. Create cite extract script
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: Literature
- **Dependencies**: None

**Description**: Create cite-extract.sh script at .claude/extensions/literature/scripts/cite-extract.sh for citation claim extraction from text. Detect patterns: author-year references (Smith 2020), parenthetical citations (Smith, 2020), "according to X", "as shown by X", theorem/lemma attributions, direct quotes with attribution. Output JSON array of {claim, source_text, line_number, confidence}. Script reads from stdin or file path argument. Used by skill-cite to identify claims needing verification.

---

### 715. Update literature extension docs
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 714

**Description**: Update literature extension documentation to reflect Zotero search and import capabilities added by tasks 711 and 714. Assumes task 710 has already updated literature-organization.md and core documentation for centralized architecture. Files: (1) .claude/extensions/literature/manifest.json -- add zotero-search.sh to provides.scripts, update description. (2) .claude/extensions/literature/EXTENSION.md -- document Zotero search workflow and import pipeline. (3) .claude/extensions/literature/README.md -- update with new search/import capabilities. (4) CLAUDE.md merge source -- update /literature command usage table with --search and --task modes. (5) Regenerate CLAUDE.md. Also update any references in other extensions (lean, formal) that mention specs/literature/ to note centralized alternative.

---

### 714. Enhance literature command zotero
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 711

**Description**: Enhance the /literature command and skill-literature to support Zotero search and import targeting the centralized Literature/ repo. Assumes task 710 has already implemented LITERATURE_DIR env var and centralized repo structure. New capabilities: (1) New search mode: /literature --search "query" -- searches zotero-library.json (via zotero-search.sh from task 711) and existing Literature/ index for matching entries. (2) Interactive source selection via AskUserQuestion -- present ranked results showing title, author, year, availability (PDF exists / already converted / not available). (3) Import pipeline: for selected Zotero entries with PDFs, symlink PDF to Literature/ repo, run convert flow, generate index entry, commit to Literature/ repo. (4) Task-number mode: /literature --task N reads the task description and uses it as the search query. Update commands/literature.md, skill-literature/SKILL.md, and agents/literature-agent.md.

---

### 713. Update literature retrieve centralized
- **Status**: [ABANDONED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 710, Task 712

**Description**: Update .claude/extensions/core/scripts/literature-retrieve.sh (and live copy at .claude/scripts/literature-retrieve.sh) to read from the centralized Literature/ repo instead of per-repo specs/literature/. Changes: (1) Replace PROJECT_ROOT/specs/literature path resolution with LITERATURE_DIR environment variable (default: ~/Projects/Literature/). (2) Preserve keyword-based scoring and greedy selection within TOKEN_BUDGET. (3) Handle the case where LITERATURE_DIR does not exist (silent exit, same as current specs/literature/ missing behavior). (4) Update fallback path to check centralized repo. (5) Keep backward compatibility: if LITERATURE_DIR is not set and specs/literature/ exists locally, prefer local (or configurable priority). (6) Sync both script copies. Also update literature-organization.md guide to reference centralized path.

---

### 712. Migrate literature centralized repo
- **Status**: [ABANDONED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 710

**Description**: Migrate existing literature content from per-repo specs/literature/ directories to the centralized ~/Projects/Literature/ repository. Sources: (1) /home/benjamin/Projects/BimodalLogic/specs/literature/ -- 23 subdirectories + 3 standalone PDFs with markdown. (2) /home/benjamin/Projects/cslib/specs/literature/ -- 12 entries (mix of subdirectories and standalone files). Steps: (1) Identify overlapping entries (both repos have blackburn_2001, burgess_1982, etc.). (2) Merge content, preferring the more complete version for duplicates. (3) Create unified index.json with enhanced schema (author, year, bib_key, title, section, path, page_range, token_count, keywords, summary, document_type, source_format). (4) Organize into author_year/ subdirectories with consistent naming. (5) Set up .gitignore for PDF/DJVU source files. (6) Commit initial content to the Literature/ repo. Do NOT delete per-repo specs/literature/ (user handles cleanup).

---

### 711. Create zotero search script
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 710

**Description**: Create a Zotero search script at .claude/extensions/literature/scripts/zotero-search.sh. The script searches ~/Projects/Literature/zotero-library.json (Better BibTeX CSL-JSON auto-export, configurable via ZOTERO_LIBRARY env var) using jq. Features: (1) CSL-JSON entry search via jq -- no BibTeX parsing or LaTeX escaping needed. (2) Multi-field search across title, author, abstract fields. (3) PDF availability check -- resolve file paths from Zotero storage, verify files exist on disk. (4) Ranked results by keyword relevance score. (5) JSON output format with bib_key, title, authors, year, type, pdf_paths (existing only), abstract snippet. Note: task 710 establishes the centralized Literature/ repo and LITERATURE_DIR env var; this script builds on that foundation. Register in literature extension manifest.

---

### 710. Research centralized literature zotero
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**:
  - [710_research_centralized_literature_zotero/reports/01_team-research.md]
  - [710_research_centralized_literature_zotero/reports/02_sqlite-vs-json-research.md]
- **Plan**: [710_research_centralized_literature_zotero/plans/02_centralized-literature-plan.md]

**Description**: Research architecture for centralizing literature management across repos with Zotero.bib integration. Analyze: (1) Zotero.bib format at ~/texmf/bibtex/bib/Zotero.bib -- BibTeX parsing, file field for PDF paths, entry structure. (2) Current per-repo specs/literature/ in BimodalLogic (23 entries) and cslib (12 entries) -- overlap analysis, index.json schema differences. (3) Centralized ~/Projects/Literature/ repo structure design -- directory layout, unified index.json with enhanced metadata (author, year, bib_key, document type, source format). (4) Cross-repo path resolution via LITERATURE_DIR environment variable with ~/Projects/Literature/ default. (5) How /literature command and --lit flag should discover and operate on the centralized repo from any project. (6) PDF storage strategy -- copy from Zotero storage to Literature/ or symlink. Deliverable: architecture report covering all 6 areas with concrete design decisions.

---

### 709. Add pr ready orchestrate support
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Add pr_ready state handling and pr_description artifact support to skill-orchestrate so the orchestate skill properly handles the PR lifecycle for cslib extension pr tasks. Four changes to .claude/skills/skill-orchestrate/SKILL.md: (1) Stage 4 state handler: add a pr_ready case (alongside completed) that exits cleanly with a message directing the user to run /pr N -- currently pr_ready falls through to Unknown state and exits with partial. (2) Stage 5 postflight dispatch_status: add pr_ready to the case statement (after implemented) so skill_postflight_update runs for the implement operation -- currently falls to * with no update. (3) Stage 5 artifact linking: add pr_description to the artifact type case so PR descriptions get linked in TODO.md using field name **PR Description** with next_field **Description**. (4) Multi-task section parity: apply the same three additions to the multi-task section (Stage MT state filtering at line ~830, dispatch_status case at line ~997, artifact type case at line ~1021). The full lifecycle (research -> plan -> implement -> pr_ready) is preserved. No testing pipeline changes needed.

---

### 708. Add filetypes dependency to literature extension manifest
- **Status**: [ABANDONED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Add filetypes to the dependencies array in .claude/extensions/literature/manifest.json so that when literature is loaded via the <leader>al picker, filetypes tools (PDF/DJVU conversion via superdoc MCP) are automatically available. Change dependencies from ["core"] to ["core", "filetypes"].

---

### 707. Refactor literature extension: co-location, logical chunking, enhanced metadata
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Three convention changes to the literature extension: (1) PDF/DJVU source files must be co-located with their markdown in the same directory, gitignored via specs/literature/**/*.pdf and *.djvu patterns. Update convert flow and SKILL.md accordingly. (2) Replace fixed 10-page-per-chunk approach with content-aware logical splitting at 4,000-line threshold -- divide books into chapters, long chapters into sections, etc. (3) Enhance index.json schema to include author, title, year, document type (paper/book/chapter/section), source format (pdf/djvu), parent document reference (for chunks), page range, and other retrieval-useful fields. Update SKILL.md, EXTENSION.md, agents/literature-agent.md, and commands/literature.md.

---

### 706. Revise pr description format template
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Plan**: [706_revise_pr_description_format_template/plans/01_implementation-plan.md]

**Description**: Revise .claude/extensions/cslib/context/project/cslib/standards/pr-description-format.md based on the real-world PR description at /home/benjamin/Projects/cslib/specs/198_submit_propositional_upstream_pr/pr-description.md. Four additions: (1) Add a 'Breaking Changes' section (required when applicable) listing renamed identifiers, removed constraints, changed signatures, and affected downstream files -- modeled on the task 198 PR's enumeration of constructor renames and constraint removals. (2) Add a 'Relationship to Other PRs' section (required when applicable) for documenting concurrent/adjacent PRs with interaction context -- broader than the current 'stacked on' pattern under Context, covering lateral PRs that touch the same files or related concerns (e.g., PR #607 overlaps in propositional connectives, PR #536 modifies the same files independently). (3) Add a 'Contribution Roadmap' section (optional) for multi-PR contribution series -- numbered list of planned follow-up PRs with scope summaries, link to development branch. (4) Revise the 'Changed Files' format to offer a simpler linked format alongside the existing diff-stat format: `[File](link) -- **New/Modified**: description` per file, which is cleaner for PRs with fewer files. Keep the diff-stat + H3 format as the option for larger PRs (10+ files). Also standardize the title format and harmonize AI disclosure section naming. File: .claude/extensions/cslib/context/project/cslib/standards/pr-description-format.md.

---

### 705. Create build cache strategy guide
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Create a build cache strategy context document at .claude/extensions/cslib/context/project/cslib/tools/build-cache-strategy.md documenting: (1) Mathlib cloud cache architecture -- how `lake exe cache get` downloads pre-built .olean files for Mathlib dependencies so only CSLib's own modules need rebuilding, (2) when cache invalidation occurs -- branch divergence from upstream/main, toolchain version changes, Mathlib version bumps, (3) the upstream/main base build strategy -- keeping a built checkout of upstream/main as a cache foundation for feature branches that diverge only slightly, (4) `lake exe cache get` usage patterns -- when to run (after branch creation, after Mathlib version bump), expected time savings, interaction with `lake build`, (5) feature branch workflow -- why creating from upstream/main with diverged fork main invalidates cache, and the two mitigation strategies. Register in cslib index-entries.json with load_when for cslib-implementation-agent and pr task types. Files: .claude/extensions/cslib/context/project/cslib/tools/build-cache-strategy.md, .claude/extensions/cslib/index-entries.json.

---

### 704. Update ci pipeline cache management
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Update ci-pipeline.md and lake-commands.md in the cslib extension context to include Mathlib cache management. Add a new Step 0 (Cache Setup) to ci-pipeline.md before Step 1 (lake build): run `lake exe cache get` to download pre-built Mathlib .olean files when working on a feature branch. This step is critical when the feature branch is based on upstream/main and the local fork's main has diverged -- without cache fetching, `lake build` performs a near-full rebuild of Mathlib (30+ minutes). Add `lake exe cache get` to lake-commands.md under a new 'Cache Management Commands' section with usage, expected behavior, and when to use it. Note that cache get only needs to run once per branch setup, not on every build. Files: .claude/extensions/cslib/context/project/cslib/standards/ci-pipeline.md, .claude/extensions/cslib/context/project/cslib/tools/lake-commands.md.

---

### 703. Create literature organization guide
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Create a context guide at .claude/context/guides/literature-organization.md documenting specs/literature/ conventions: directory structure (flat files vs author_year/ subdirectories), index.json schema (entries[] format with id, bib_key, title, authors, year, section, path, page_range, token_count, keywords, summary), subdirectory index formats (chapters[] for books), naming conventions (Author_Year_Title.md for flat, secNN_slug.md for chapters), chunk sizing policy (~4000 tokens max per file), how --lit injection works (keyword scoring, greedy budget selection), and how to manually add new papers. Register in .claude/context/index.json with load_when for research agents and --lit operations. Files: .claude/context/guides/literature-organization.md, .claude/context/index.json.

---

### 702. Create literature command
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 701

**Description**: Create a /literature command (command + skill + agent) for managing specs/literature/ directories. The command should: (1) Scan for unprocessed PDFs and DJVU files that lack corresponding markdown conversions, (2) Convert them to markdown chunked at ~4000 tokens per file using available CLI tools (pdftotext, pandoc, djvutxt), (3) Generate/update index.json entries for new conversions with keywords, summary, token_count, (4) Validate existing index.json entries against the filesystem (detect missing files, stale paths, token count drift), (5) Report status showing processed vs unprocessed files and index health. Research June 2026 best practices for PDF-to-markdown conversion quality. Files: .claude/commands/literature.md, .claude/skills/skill-literature/SKILL.md, .claude/agents/literature-agent.md.

---

### 701. Upgrade literature retrieve script
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [701_upgrade_literature_retrieve_script/reports/01_upgrade-lit-retrieve.md]

**Description**: Upgrade literature-retrieve.sh to fix TOKEN_BUDGET mismatch (script uses 4000 but index.json declares 40000), make budget configurable via index.json token_budget field with fallback default of 8000, and add recursive subdirectory index.json merging to handle both entries[] and chapters[] formats (e.g., blackburn_2001/index.json uses chapters[] while main index uses entries[]). Unify all discoverable entries into a single scored selection. Files: .claude/extensions/core/scripts/literature-retrieve.sh, .claude/scripts/literature-retrieve.sh.

---

### 700. Update pr workflow docs
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 698, Task 699
- **Summary**: [700_update_pr_workflow_docs/summaries/01_pr-docs-update-summary.md]

**Description**: Update documentation to reflect the revised PR workflow separation: skill-pr-implementation produces pr-description.md only (no branch, no CI), /pr N creates branch + runs CI + submits. Update: (1) cslib extension EXTENSION.md skill table description for skill-pr-implementation, (2) pr-prohibition.md rule to reference the new workflow (skill prepares description, /pr handles submission), (3) any context files referencing the old combined workflow. Ensure the cslib manifest.json routing entries for pr task type are still correct after the skill revision. Sync extension core copies of any changed rules.

---

### 699. Revise pr command branch ci submit
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Revise the /pr command to be the single entry point for feature branch creation, CI verification, and PR submission. When invoked as /pr N: (1) read pr-description.md from the task directory as the PR body (required -- error if missing), (2) create the feature branch from upstream/main (STEP 5), (3) stage relevant changes (STEP 6), (4) run `lake exe cache get` to fetch Mathlib's pre-built .olean cache so only CSLib modules need rebuilding (critical when the feature branch diverges from main -- without this, branch creation from upstream/main triggers a near-full rebuild), (5) run 7-step CI pipeline (STEP 7), (6) if all tests pass, present pr-description.md content and ask user for approval to submit, (7) submit the PR via gh pr create with the pr-description.md content, (8) transition task to [COMPLETED]. Remove the fallback interactive description composition flow (Steps 8-9 for non-task modes) when pr-description.md exists -- the description is pre-built by skill-pr-implementation. Preserve path-mode and description-mode as fallback for non-task PR submissions. File: .claude/extensions/cslib/commands/pr.md.

---

### 698. Revise skill pr description only
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Revise skill-pr-implementation to focus exclusively on analyzing changes and producing pr-description.md as its final output. Remove all feature branch creation logic (git checkout upstream/main -b feat/{slug}) and CI verification logic (7-step pipeline) from the skill. The revised skill should: (1) research what commits/files to include or exclude in the PR based on the task description, (2) analyze the diff to compose a pr-description.md following the canonical format from pr-description-format.md, (3) write pr-description.md to specs/{NNN}_{SLUG}/, (4) transition the task to [PR READY]. Update the delegation context in Stage 3 to remove pr_branch_strategy and ci_verification_mode fields. Update the MUST NOT section to clarify that branch creation and CI are handled by /pr command, not this skill. Also update the cslib-implementation-agent PR-specific delegation context to match the new scope. Files: .claude/extensions/cslib/skills/skill-pr-implementation/SKILL.md, .claude/extensions/cslib/agents/cslib-implementation-agent.md (PR delegation sections).

---

### 697. Fix literature retrieve keyword matching
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [697_fix_literature_retrieve_keyword_matching/reports/01_literature-retrieve-research.md]
- **Plan**: [697_fix_literature_retrieve_keyword_matching/plans/01_implementation-plan.md]
- **Summary**: [697_fix_literature_retrieve_keyword_matching/summaries/01_implementation-summary.md]

**Description**: Rewrite .claude/scripts/literature-retrieve.sh to use specs/literature/index.json for keyword-based file selection instead of naive alphabetical top-level file scanning. Current script has 4 defects identified by cslib audit (task 200): (1) -maxdepth 1 only finds top-level files, missing chapter splits in subdirectories; (2) description and task_type arguments captured but never used for selection; (3) no index.json integration for keyword matching; (4) alphabetical ordering instead of relevance-based selection. Fix should: read index.json entries, tokenize description into keywords, score entries by keyword overlap, sort by relevance score (descending), select top matches within TOKEN_BUDGET=4000 and MAX_FILES=10, read matched files and output <literature-context> block. When index.json is absent, fall back to current behavior (scan for small files). Sync extension core copy at .claude/extensions/core/scripts/literature-retrieve.sh. Reference: /home/benjamin/Projects/cslib/specs/200_fix_literature_directory_quality/reports/01_literature-quality-audit.md Priority 1 recommendation.

---

### 696. Apply pr deny rules fix hook
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [696_apply_pr_deny_rules_fix_hook/reports/01_pr-deny-rules-research.md]
- **Plan**: [696_apply_pr_deny_rules_fix_hook/plans/01_implementation-plan.md]
- **Summary**: [696_apply_pr_deny_rules_fix_hook/summaries/01_pr-deny-rules-summary.md]

**Description**: Apply PR deny rules to settings.json and fix the block-pr-submission.sh hook. Three changes: (1) Add Bash(gh pr create*) and Bash(gh pr merge*) to permissions.deny in .claude/settings.json — these force a harness-level permission prompt that cannot be bypassed by model behavior. Do NOT add git push to deny (user wants push allowed). (2) Update .claude/hooks/block-pr-submission.sh to remove the git push block (lines 25-28) — user explicitly wants agents to be able to push branches. Keep gh pr create and glab mr create blocks. (3) Register block-pr-submission.sh in the PreToolUse hooks array in .claude/settings.json with matcher Bash — Task 684 created the script but never wired it into settings.json. Also sync the hook script to .claude/extensions/core/hooks/block-pr-submission.sh if that path exists. Background: Tasks 684-685 were marked completed but their settings.json changes were never applied. The /orchestrate command then submitted a PR to upstream leanprover/cslib without user approval because Bash(git:*) in the allow list auto-approved all git/gh commands.

---

### 695. Artifact reconciliation sync
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [695_artifact_reconciliation_sync/reports/01_artifact-reconciliation-research.md]
- **Plan**: [695_artifact_reconciliation_sync/plans/01_implementation-plan.md]
- **Summary**: [695_artifact_reconciliation_sync/summaries/02_artifact-reconciliation-summary.md]

**Description**: Add artifact reconciliation to /task --sync. Currently, tasks can have artifact files on disk (reports/, plans/, summaries/) that are not tracked in state.json artifacts array, making them invisible in TODO.md. Add a reconciliation step to --sync mode that scans each active task directory for .md files in reports/, plans/, and summaries/ subdirectories, compares against state.json artifacts entries, and backfills any missing entries with inferred type (research/plan/summary from directory name). Evidence: cslib tasks 191 and 193 have artifacts on disk but not in state.json. Postflight scripts correctly register new artifacts but pre-existing gaps are never repaired.

---

### 694. Fix task title derivation
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [694_fix_task_title_derivation/reports/01_title-derivation-research.md]
- **Plan**: [694_fix_task_title_derivation/plans/01_implementation-plan.md]
- **Summary**:
  - [694_fix_task_title_derivation/summaries/02_title-derivation-summary.md]
  - [694_fix_task_title_derivation/summaries/02_title-derivation-summary.md]

**Description**: Fix task title derivation in task.md step 6. Currently sets "title": $desc which makes the title identical to the full description (see cslib task 197 for example). The title should be a short human-readable string derived from project_name (capitalize first letter, replace underscores with spaces), matching the fallback behavior in generate-todo.sh lines 192-196. The description field should remain as-is. Also applies to task.md expand mode (step 3) and any other task creation flows that use the same jq template pattern. Fix should also clean up cslib task 197 state.json entry to remove the overly long title field.

---

### 693. Fix lit flag missing script
- **Status**: [ABANDONED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [693_fix_lit_flag_missing_script/reports/01_lit-flag-research.md]

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
- **Summary**: [682_extension_keyword_overrides_task_command/summaries/03_execution-summary.md]

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
- **Summary**: [679_research_tts_best_practices/summaries/01_verification-summary.md]

**Description**: Web research on current Claude Code hook patterns for TTS/audio notifications as of June 2026. Compare with the existing Piper TTS + WezTerm tab color notification pipeline. Identify: (1) any new hook events beyond Stop/Notification/SubagentStop that could improve notification targeting, (2) best practices for deduplication and cooldown in multi-agent workflows, (3) whether the Notification hook matcher "permission_prompt|elicitation_dialog" is still the correct set of actionable notification types, (4) integration patterns between TTS announcements and terminal tab visual indicators. Document findings for tasks 680 and 681.

---

### 678. Adaptive auto-escalation advisory (v2)
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669
- **Research**: [678_auto_escalation_advisory_v2/reports/01_auto-escalation-research.md]
- **Plan**: [678_auto_escalation_advisory_v2/plans/01_auto-escalation-plan.md]
- **Summary**: [678_auto_escalation_advisory_v2/summaries/01_auto-escalation-summary.md]

**Description**: Implement churn detection that emits a 'consider --hard' warning when repeated deflection patterns are observed: 2+ plan revisions on a single task, 3+ implement dispatches with no phase completion, or analysis-only output in implementation phases. This is advisory only -- does not auto-escalate. v2 trajectory item. Research inputs: specs/669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md, specs/669_hard_mode_agent_system/reports/02_team-research.md.

---

### 677. Contract lint and testing strategy for hard-mode behavioral correctness
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669
- **Plan**: [677_contract_lint_testing_strategy/plans/01_contract-lint-plan.md]
- **Research**: [677_contract_lint_testing_strategy/reports/01_contract-lint-research.md]
- **Summary**: [677_contract_lint_testing_strategy/summaries/01_contract-lint-summary.md]

**Description**: Design and implement a testing strategy for hard-mode behavioral correctness: contract lint rules that verify agents honor anti-analysis budgets, reference grounding requirements, and convergence policing thresholds. May include test harnesses that replay known deflection-prone prompts against hard-mode agents and check for contract violations. Research inputs: specs/669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md, specs/669_hard_mode_agent_system/reports/02_team-research.md.

---

### 676. Add hard-mode routing to cslib extension
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669
- **Plan**: [676_cslib_extension_hard_mode_variants/plans/01_cslib-hard-mode-plan.md]
- **Research**: [676_cslib_extension_hard_mode_variants/reports/01_cslib-hard-mode-research.md]
- **Summary**: [676_cslib_extension_hard_mode_variants/summaries/01_cslib-hard-mode-summary.md]

**Description**: Add hard-mode routing to the cslib extension following the same pattern as lean4: routing_hard manifest entries, skill-cslib-research-hard, skill-cslib-implementation-hard, cslib hard agents with domain-specific H-technique overrides. Research inputs: specs/669_hard_mode_agent_system/reports/01_hard-mode-orchestration-approach.md, specs/669_hard_mode_agent_system/reports/02_team-research.md.

---

### 675. Add hard-mode routing to lean4 extension
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 669
- **Research**: [675_lean4_extension_hard_mode_variants/reports/01_lean4-hard-mode-research.md]
- **Plan**: [675_lean4_extension_hard_mode_variants/plans/01_lean4-hard-mode-plan.md]
- **Summary**: [675_lean4_extension_hard_mode_variants/summaries/01_lean4-hard-mode-summary.md]

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
- **Summary**: [670_fix_artifact_counter_system/summaries/03_execution-summary.md]

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
  - [669_hard_mode_agent_system/reports/02_teammate-a-findings.md]
  - [669_hard_mode_agent_system/reports/02_teammate-b-findings.md]
  - [669_hard_mode_agent_system/reports/02_teammate-c-findings.md]
  - [669_hard_mode_agent_system/reports/02_teammate-d-findings.md]
- **Plan**: [669_hard_mode_agent_system/plans/02_hard-mode-implementation.md]
- **Summary**: [669_hard_mode_agent_system/summaries/02_hard-mode-implementation-summary.md]

**Description**: Create hard-mode variants of the agent system for very complex, deflection-prone tasks (e.g., deep Lean formalization): route --hard in /implement, /research, /plan, /orchestrate to hard-mode skills (skill-lean-implementation-hard, skill-orchestrate-hard, skill-planner-hard, skill-{domain}-research-hard) calling hard-mode agents. Hard mode encodes: per-phase dispatch (one bounded milestone per agent run), anti-analysis prompt contracts (read budgets, forbidden conclusions, counterexample bar for defect claims), prior-art transcription mandates with PDF-level citation, adversarial verification of research reports, divergence-audit trigger after repeated deflections (churn counters in loop guard), territory contracts for parallel dispatch, roadmap handoffs with incremental commit discipline, and hard-mode plan format (phases sized for single runs, postmortem constraints, lemma-to-source mapping, preserved-assets accounting). See report 01 for the full methodology distilled from the BimodalLogic task-273 session, measured outcomes, and a 7-step implementation breakdown.

---

### 668. Add default_task_type support to task creation pipeline
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [668_add_default_task_type_support/reports/01_default-task-type.md]
- **Plan**: [668_add_default_task_type_support/plans/01_default-task-type.md]
- **Summary**: [668_add_default_task_type_support/summaries/01_default-task-type-summary.md]

**Description**: Add a default_task_type field to state.json that projects can set to override the hardcoded keyword table in task.md step 4. When default_task_type is present, task.md uses it as the task type for all new tasks except those matching meta keywords (meta/agent/command/skill), which always override to meta since they modify .claude/ itself. This fixes the problem where CSLib tasks get lean4 or formal instead of cslib because the keyword table matches proof/theorem/lean/logic keywords before the cslib extension routing is consulted. Changes: (1) Modify task.md step 4 to read default_task_type from state.json via jq, use it as default when set, only allow meta keywords to override. (2) Sync extension copy at extensions/core/commands/task.md. (3) Update state-management-schema.md to document the new field. (4) Document in CLAUDE.md state.json schema section.

---

### 667. Create cslib /pr command
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663
- **Research**: [667_create_cslib_pr_command/reports/01_pr-command-research.md]
- **Plan**: [667_create_cslib_pr_command/plans/01_pr-command-plan.md]
- **Summary**: [667_create_cslib_pr_command/summaries/01_pr-command-summary.md]

**Description**: Create a /pr command for the cslib extension that accepts a task number, path (file or directory), or description to cherry-pick elements from main branch onto a feature branch, clean up code to CSLib quality standards, run the full CI pipeline (lake build, lake exe checkInitImports, lake lint, lake exe lint-style, lake shake --add-public --keep-implied --keep-prefix, lake exe mk_all --module, lake test), submit PR with user approval (conventional commit title: feat/fix/doc/style/refactor/test/chore/perf, AI disclosure in description), and merge back to main with user approval. Deliverables: command file at .claude/extensions/cslib/commands/pr.md, manifest.json provides.commands update, and optionally a dedicated skill-cslib-pr skill if complexity warrants separation.

---

### 666. Create cslib context and rules
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663
- **Research**: [666_create_cslib_context_rules/reports/01_cslib-context-rules-research.md]
- **Plan**: [666_create_cslib_context_rules/plans/01_cslib-context-rules-plan.md]
- **Summary**: [666_create_cslib_context_rules/summaries/01_context-rules-summary.md]

**Description**: Create rules/cslib.md (path pattern: **/*.lean for CSLib project) and context files under context/project/cslib/ covering: domain/ (CONTRIBUTING standards, notation conventions, project organization), patterns/ (proof structure, module organization, reuse-first philosophy), standards/ (CI pipeline, PR conventions, conventional commits, mathlib style), tools/ (lake commands, linters, checkInitImports, mk_all, lint-style, lake shake). CSLib-specific encoding: alpha equivalence notation, LTS transitions, reduction arrows from NOTATION.md. Working groups model and AI usage policy from CONTRIBUTING.md. Additionally, incorporate citation conventions from /home/benjamin/Projects/cslib/.claude/context/standards/citation-conventions.md as a new context file at context/project/cslib/standards/citation-conventions.md — this covers BibKey format (CamelCase, e.g. Blackburn2001), the references.bib workflow, canonical citation display format in module docstrings, and legacy pattern conversion rules.

---

### 665. Create cslib skills
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663
- **Research**: [665_create_cslib_skills/reports/01_cslib-skills-research.md]
- **Plan**: [665_create_cslib_skills/plans/01_cslib-skills-plan.md]
- **Summary**: [665_create_cslib_skills/summaries/01_skills-summary.md]

**Description**: Create skill-cslib-research/SKILL.md and skill-cslib-implementation/SKILL.md at .claude/extensions/cslib/skills/. Research skill delegates to cslib-research-agent with tools: lean-lsp MCP (inherited via lean dependency), WebSearch, WebFetch, Read, Bash. Implementation skill delegates to cslib-implementation-agent with tools: Read, Write, Edit, Bash (lake build, lake test, lake lint, lake exe checkInitImports, lake exe lint-style, lake shake). Both skills follow thin-wrapper pattern delegating to their respective agents.

---

### 664. Create cslib agents
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 663
- **Research**: [664_create_cslib_agents/reports/01_cslib-agents-research.md]
- **Plan**: [664_create_cslib_agents/plans/01_cslib-agents-plan.md]
- **Summary**: [664_create_cslib_agents/summaries/01_agents-summary.md]

**Description**: Create cslib-research-agent.md (model: opus) and cslib-implementation-agent.md (model: sonnet) at .claude/extensions/cslib/agents/. Research agent: inherits lean-lsp MCP tools via lean dependency, focuses on CSLib-specific formalization patterns, mathlib API discovery, typeclass-based abstraction. Implementation agent: CI verification pipeline (lake test, lake exe checkInitImports, lake lint, lake exe lint-style, lake shake --add-public --keep-implied --keep-prefix), Cslib.Init import enforcement, mathlib style compliance, proof readability over golfing.

---

### 663. Create cslib extension scaffold
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [663_create_cslib_extension_scaffold/reports/01_extension-scaffold-research.md]
- **Plan**: [663_create_cslib_extension_scaffold/plans/01_extension-scaffold-plan.md]
- **Summary**: [663_create_cslib_extension_scaffold/summaries/01_scaffold-summary.md]

**Description**: Create the cslib extension scaffold at .claude/extensions/cslib/ modeled after the lean extension. Includes: manifest.json (task_type: "cslib", dependencies: ["core", "lean"], provides agents/skills/rules/context, routing table for research/plan/implement, no mcp_servers since lean-lsp inherited via lean dependency), EXTENSION.md (CLAUDE.md merge content for cslib section), README.md (extension documentation), index-entries.json (context discovery entries for cslib agents/task_types), and directory structure (agents/, skills/, commands/, rules/, context/project/cslib/{domain,patterns,standards,tools}/).

---

### 662. Wire postflight lifecycle notifications end-to-end
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Topic**: Terminal UI
- **Dependencies**: Task 661
- **Research**: [662_wire_postflight_lifecycle_notifications/reports/01_wire-lifecycle-notify.md]
- **Plan**: [662_wire_postflight_lifecycle_notifications/plans/01_wire-lifecycle-notify.md]

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
- **Research**: [656_add_topic_assignment_gaps/reports/01_add-topic-gaps.md]
- **Plan**: [656_add_topic_assignment_gaps/plans/01_add-topic-gaps-plan.md]
- **Summary**: [656_add_topic_assignment_gaps/summaries/01_add-topic-gaps-summary.md]

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
- **Research**: [655_refactor_existing_topic_pickers/reports/01_refactor-topic-pickers.md]
- **Plan**: [655_refactor_existing_topic_pickers/plans/01_refactor-topic-pickers-plan.md]
- **Summary**: [655_refactor_existing_topic_pickers/summaries/01_refactor-topic-pickers-summary.md]

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
- **Research**: [654_create_topic_management_utilities/reports/01_topic-management-research.md]
- **Summary**: [654_create_topic_management_utilities/summaries/01_topic-management-summary.md]

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
- **Research**:
  - [647_enrich_state_json_schema/reports/01_team-research.md]
  - [647_enrich_state_json_schema/reports/01_teammate-a-findings.md]
  - [647_enrich_state_json_schema/reports/01_teammate-c-findings.md]
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
- **Research**: [639_fix_orchestrate_todo_sync/reports/01_todo-sync-analysis.md]
- **Plan**: [639_fix_orchestrate_todo_sync/plans/01_fix-todo-sync-plan.md]

**Description**: Replace bash function references in skill-orchestrate/SKILL.md with explicit, standalone bash commands that the orchestrator agent can execute directly via the Bash tool. The orchestrator currently updates state.json correctly but never updates TODO.md status markers or links artifacts because it treats skill_preflight_update, skill_postflight_update, and skill_link_artifact_from_handoff as pseudocode rather than callable functions (they require source skill-base.sh which agents don't run). Changes needed in both single-task (Stages 4-5) and multi-task (Stages MT-3/MT-4) sections.

---

### 638. Fix generate-task-order.sh to create Task Order section when missing
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [638_fix_generate_task_order_missing_section/reports/01_missing-section-analysis.md]
- **Plan**: [638_fix_generate_task_order_missing_section/plans/01_fix-task-order-bootstrap.md]
- **Summary**: [638_fix_generate_task_order_missing_section/summaries/01_fix-summary.md]

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
