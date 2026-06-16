---
next_project_number: 739
---

# TODO

## Task Order

*Updated 2026-06-16. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87 | -- | Terminal UI, Email Integration |

**Grouped by Topic** (indented = depends on parent):

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 738. Refactor BimodalLogic specs/literature/ to sources/ structure and remove blackburn_2001
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: None

**Description**: Refactor ~/Projects/BimodalLogic/specs/literature/ to match the centralized Literature/ repository structure: (1) Create sources/ subdirectory, (2) Move all 23 content subdirectories into sources/, (3) Move 30 loose markdown files into individual sources/{id}/ directories, (4) Move 3 loose PDFs (Hodkinson_Reynolds_2006, Libkin_2004, Rabinovich_2014) alongside their content in sources/, (5) Remove blackburn_2001/ directory entirely (matching Literature/ removal), (6) Update index.json paths with sources/ prefix and remove blackburn_2001 entries, (7) Update README.md references.

---

### 737. Refactor cslib specs/literature/ to sources/ structure and remove blackburn_2001
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: None

**Description**: Refactor ~/Projects/cslib/specs/literature/ to match the centralized Literature/ repository structure: (1) Create sources/ subdirectory, (2) Move all 7 content subdirectories (church_1956, chagrov_1997, gentzen_1935, hughes_1996, mendelson_2016, zakharyaschev_2001) into sources/, (3) Move 11 loose markdown files into individual sources/{id}/ directories, (4) Move chagrov_1997.djvu alongside its content in sources/, (5) Remove blackburn_2001/ directory entirely (matching Literature/ removal), (6) Update index.json paths with sources/ prefix and remove blackburn_2001 entries, (7) Update README.md references.

---

### 736. Update literature extension for sources/ directory convention
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: literature
- **Dependencies**: None

**Description**: Update the literature extension to use the sources/ subdirectory convention matching the refactored ~/Projects/Literature/ repository. Changes needed: (1) skill-literature SKILL.md convert mode should place new conversions under sources/ instead of flat in lit_dir, (2) EXTENSION.md should document the sources/ convention, (3) literature-retrieve.sh fallback path should look in sources/ subdirectory for markdown files. The index-based path (Tier 1/2) already works because paths come from index.json. The migrate-from-repo.sh in Literature/ was already updated.

---

### 735. Add project-aware literature filtering with project_tags population and retrieval filtering
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: None

**Description**: Add project-aware literature filtering: scan BimodalLogic and cslib source files to populate project_tags in ~/Projects/Literature/index.json, then add project-aware filtering to literature-retrieve.sh (auto-detect project from $PWD, prefer entries with matching project_tags). Tier 1 FTS5 queries should filter by project; Tier 2 keyword injection should prefer project-tagged entries. Entries with no project_tags remain available as fallback.

---

### 734. Optimize cslib build cache strategy
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**:
  - [734_optimize_cslib_build_cache_strategy/reports/01_build-cache-research.md]
  - [734_optimize_cslib_build_cache_strategy/reports/02_detailed-change-spec.md]
- **Plan**: [734_optimize_cslib_build_cache_strategy/plans/03_cache-optimization-plan.md]
- **Summary**: [734_optimize_cslib_build_cache_strategy/summaries/03_cache-optimization-summary.md]

**Description**: Optimize CSLib build cache strategy: add lake exe cache get to cslib-implementation-agent CI pipeline, skill preflight cache warming, fix rules CI order, and defer redundant lake test for pr-type tasks — to eliminate 30-45 min Mathlib rebuilds during implementation

---

### 733. Wire LITERATURE_DIR globally, build FTS5 database, validate unified collection
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: Task 732
- **Research**: [733_literature_infrastructure_wiring/reports/01_infrastructure-wiring-research.md]
- **Plan**: [733_literature_infrastructure_wiring/plans/01_infrastructure-wiring-plan.md]
- **Summary**: [733_literature_infrastructure_wiring/summaries/01_infrastructure-wiring-summary.md]

**Description**: Move LITERATURE_DIR setting to ~/.dotfiles/config/claude/settings.json (Home Manager-managed global settings) so all projects pick it up. Remove the per-project setting from nvim's .claude/settings.json. Build the FTS5 database (.literature.db) using literature-build-index.sh to activate Tier 1 on-demand search (currently dead code — always falls back to Tier 2 keyword injection). Run literature-audit.sh to validate index integrity across the unified collection. Verify --lit flag works end-to-end from all three project roots (nvim, BimodalLogic, cslib).

---

### 732. Unify index schema to v2 and clean up deprecated per-project collections
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: Task 730, Task 731
- **Research**: [732_literature_schema_unification/reports/01_schema-unification-research.md]
- **Plan**: [732_literature_schema_unification/plans/01_schema-unification-plan.md]
- **Summary**: [732_literature_schema_unification/summaries/01_schema-unification-summary.md]

**Description**: Upgrade all remaining v1 index entries in ~/Projects/Literature/index.json to v2 schema (add doc_type, source_format, zotero_key, project_tags where missing). Deduplicate BimodalLogic's flat+chunked structure (keep only semantic chunks, remove redundant flat files). Add DEPRECATED.md to cslib's specs/literature/ pointing to the centralized repo. Ensure all per-directory index.json files in subdirectories are consistent with root index.json. Validate no orphaned or missing entries.

---

### 731. Migrate cslib's 70 unique literature entries into central Literature/ repo
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: Task 728
- **Research**: [731_literature_cslib_migration/reports/01_cslib-migration-research.md]
- **Plan**: [731_literature_cslib_migration/plans/01_cslib-migration-plan.md]
- **Summary**: [731_literature_cslib_migration/summaries/01_cslib-migration-summary.md]

**Description**: Migrate cslib's 70 unique entries from ~/Projects/cslib/specs/literature/ into ~/Projects/Literature/ with v2 schema fields (doc_type, source_format, zotero_key, project_tags: ["cslib"]). Resolve the 6 overlapping entries (burgess_1982_i/ii, burgess_1984, gabbay_1994_ch10, reynolds_1992, blackburn_2001_ch00) by keeping the fuller versions and tagging both projects. Convert cslib's remaining chagrov_1997.djvu to markdown. Ensure migrated content follows semantic chunking standards from task 730.

---

### 730. Re-chunk literature files at semantic boundaries (chapter/section breaks)
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: Task 728, Task 729
- **Research**: [730_literature_semantic_rechunking/reports/01_semantic-rechunking-research.md]
- **Plan**: [730_literature_semantic_rechunking/plans/01_semantic-rechunking-plan.md]
- **Summary**: [730_literature_semantic_rechunking/summaries/01_semantic-rechunking-summary.md]

**Description**: Using the audit manifest from task 729 and source PDFs from task 728, re-chunk all arbitrarily split files at semantic boundaries (chapter headings, section headings, theorem boundaries). Chunk oversized flat files — especially the 365K-token Blackburn book. Remove redundant flat files where a properly chunked subdirectory exists. Use actual document structure from sources, not literature-chunk.sh's token-target approach. Update index.json entries for every re-chunked document with correct paths, token counts, and section metadata.

---

### 729. Audit Literature/ content quality: identify arbitrary vs semantic chunking
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: Task 728
- **Research**: [729_literature_chunking_audit/reports/01_chunking-audit-research.md]
- **Plan**: [729_literature_chunking_audit/plans/01_chunking-audit-plan.md]
- **Summary**: [729_literature_chunking_audit/summaries/01_chunking-audit-summary.md]

**Description**: Audit every subdirectory in ~/Projects/Literature/ for chunking quality. For each document, classify as: (a) semantically chunked by chapter/section (good — keep), (b) arbitrarily chunked by page number or byte count (needs re-chunking), (c) oversized flat file needing chunking (e.g., Blackburn_deRijke_Venema_2002 at 365K tokens). Also audit cslib's specs/literature/ subdirectories (blackburn_2001, chagrov_1997, church_1956, etc.) for the same. Produce a manifest of documents with their chunking status, recommended action (keep/re-chunk/chunk-new), and natural section structure from source PDFs.

---

### 728. Recover PDF/DJVU sources into Literature/pdfs/ from Zotero and project repos
- **Status**: [COMPLETED]
- **Task Type**: general
- **Topic**: literature
- **Dependencies**: None
- **Research**: [728_literature_source_recovery/reports/01_source-recovery-research.md]
- **Plan**: [728_literature_source_recovery/plans/01_source-recovery-plan.md]
- **Summary**: [728_literature_source_recovery/summaries/01_source-recovery-summary.md]

**Description**: Re-acquire PDFs/DJVUs from Zotero using zotero_key fields in ~/Projects/Literature/index.json (182/183 entries have keys). Copy BimodalLogic's 32 surviving PDFs from ~/Projects/BimodalLogic/specs/literature/ into Literature/pdfs/. Copy cslib's chagrov_1997.djvu. Verify all indexed documents have corresponding source files in pdfs/. Store in pdfs/ directory (keep gitignored but present locally). This is prerequisite for all re-chunking work.

---

### 727. Implement extension keyword_overrides lookup in /task command step 4
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [727_implement_extension_keyword_overrides_in_task_command/reports/01_keyword-overrides-research.md]
- **Plan**: [727_implement_extension_keyword_overrides_in_task_command/plans/01_keyword-overrides-plan.md]

**Description**: Fix the /task command (task.md) step 4 (task type detection) to implement the documented precedence order: meta keywords > extension keyword_overrides > default_task_type > keyword table > general. Currently step 4 only has a hardcoded keyword table and never queries extension manifests for keyword_overrides or checks state.json default_task_type. The fix should: (1) After meta keyword check, scan loaded extension manifests (.claude/extensions/*/manifest.json) for keyword_overrides entries, (2) Match task description keywords against each extension keyword_overrides, (3) If matched, use that extension task type, (4) If no extension match, check state.json default_task_type as fallback before the hardcoded keyword table, (5) Fall through to hardcoded table and then general as final default. This ensures tasks like PR-related descriptions get type pr when an extension defines pr keyword overrides.

---

### 652. Post-validation cleanup: remove obsolete scripts after logging review
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 649, Task 651, Task 653

**Description**: After ~1 week of the new pipeline running, review logs to verify the new generate-todo.sh pipeline is working reliably. Check that: (1) no deprecation-logged old code paths are being hit, (2) TODO.md regeneration succeeds consistently, (3) no state.json/TODO.md sync drift. Then remove: link-artifact-todo.sh (fully replaced by state.json + regeneration), old TODO.md awk/sed manipulation code from update-task-status.sh, dead functions from skill-base.sh, any transitional compatibility shims. Clean up deprecation logging. Mark as deferred until validation period passes.

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
