---
next_project_number: 728
---

# TODO

## Task Order

*Updated 2026-06-16. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,652 | -- | agent-system, Terminal UI, Email Integration |

**Grouped by Topic** (indented = depends on parent):

### Agent System

652 [NOT STARTED] — After ~1 week of the new pipeline running, review logs to verify 

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

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
- **Status**: [NOT STARTED]
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
