---
next_project_number: 745
---

# TODO

## Task Order

*Updated 2026-06-19. Generated from state.json dependency graph.*

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

### 744. Include pr-description.md in feature branch during /pr workflow
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 743
- **Research**: [specs/744_include_pr_description_in_feature_branch/reports/01_pr-description-copy.md]
- **Plan**: [specs/744_include_pr_description_in_feature_branch/plans/01_pr-description-copy-plan.md]

**Description**: Modify the /pr command to copy pr-description.md from specs/{NNN}_{SLUG}/ into the cslib repo (e.g., as pr-description.md at repo root) after STEP 9 and before STEP 10. The file should be left unstaged (not git-added) so the user can review the full PR description alongside the code changes before pushing. This gives the user a convenient way to inspect the PR description in the context of the feature branch. Files to modify: .claude/extensions/cslib/commands/pr.md

---

### 743. Standardize AI Tools Used section across PR templates and agents
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [specs/743_standardize_ai_tools_used_section/reports/01_ai-tools-standardization.md]
- **Plan**: [specs/743_standardize_ai_tools_used_section/plans/01_ai-tools-plan.md]

**Description**: Fix inconsistent ## AI Tools Used section in PR description generation. Three files need changes: (1) cslib-implementation-agent.md -- replace the vague [describe what it did] placeholder with a reference to the canonical template in pr-description-format.md; (2) pr.md command -- change ## AI Disclosure heading to ## AI Tools Used in the Step 9 path/description template, and align text with the canonical format; (3) pr-description-format.md is already correct (canonical source, no changes needed). Files to modify: .claude/extensions/cslib/agents/cslib-implementation-agent.md, .claude/extensions/cslib/commands/pr.md

---

### 87. Investigate terminal directory change when opening neovim in wezterm
- **Effort**: TBD
- **Status**: [RESEARCHED]
- **Task Type**: neovim
- **Topic**: Terminal UI
- **Dependencies**: None
- **Research**: [specs/087_investigate_wezterm_terminal_directory_change/reports/research-001.md]

**Description**: Investigate why the terminal working directory changes to a project root when opening neovim sessions in wezterm from the home directory (~). Determine whether this behavior is caused by neovim or wezterm (configured in ~/.dotfiles/config/). Identify if any functionality depends on this behavior before modifying it. Goal is to avoid changing the terminal directory unless necessary.

---

### 78. Fix Himalaya SMTP authentication failure when sending emails
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: neovim
- **Topic**: Email Integration
- **Dependencies**: None
- **Research**: [specs/078_fix_himalaya_smtp_authentication_failure/reports/research-001.md]
- **Plan**: [specs/078_fix_himalaya_smtp_authentication_failure/plans/implementation-001.md]

**Description**: Fix Gmail SMTP authentication failure when sending emails via Himalaya (<leader>me). Error: Authentication failed: Code: 535, Enhanced code: 5.7.8, Message: Username and Password not accepted. The error occurs with TLS connection attempts and persists through multiple retry attempts. Identify and fix the root cause of the SMTP credential configuration.
