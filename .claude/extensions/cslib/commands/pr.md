---
description: Create and submit a CSLib PR from task, path, or description with full CI verification
allowed-tools: Bash, Read, Edit, Write, AskUserQuestion
argument-hint: "<task_number | path | description> [--draft] [--dry-run] [--branch BRANCH]"
model: opus
---

# /pr Command

Create and submit a pull request to the CSLib upstream repository (`leanprover/cslib`). Accepts
a task number, file/directory path, or free-text description as input. Creates a feature branch,
runs the full 7-step CI pipeline, composes a PR using the conventional commit format, and submits
via `gh pr create`.

## Syntax

```
/pr <input> [options]
```

## Input Modes

| Input | Detection | Behavior |
|-------|-----------|----------|
| Task number (e.g., `667`) | Pure integer | Reads task description from specs/state.json |
| Path (e.g., `./Cslib/Logics/`) | Starts with `/`, `./`, or `~/`, or contains `/` | Stages changes in the path |
| Description (e.g., `prove K soundness`) | Anything else | Used as working description for branch/PR |

## Options

| Flag | Description |
|------|-------------|
| `--draft` | Create PR as draft (not ready for review) |
| `--dry-run` | Preview all steps without executing git/gh commands |
| `--branch BRANCH` | Override the auto-generated branch name |

## Execution

**EXECUTE NOW**: Follow all steps in sequence. Do not stop between steps unless instructed.

---

### STEP 1: Parse Arguments

**EXECUTE NOW**: Parse `$ARGUMENTS` to extract input mode, flags, and branch override.

```
# Defaults
input_mode=""      # "task", "path", or "description"
input_value=""     # raw user argument (before the flags)
is_draft=false
is_dry_run=false
branch_override="" # from --branch FLAG

# Parse $ARGUMENTS:
# - Extract --draft, --dry-run flags
# - Extract --branch VALUE (next token after --branch)
# - First non-flag argument is the input_value
```

Determine `input_mode` from `input_value`:
- If `input_value` is a pure integer: `input_mode="task"`
- If `input_value` starts with `/`, `./`, `~/`, or contains a path separator: `input_mode="path"`
- Otherwise: `input_mode="description"`

**On success**: **IMMEDIATELY CONTINUE** to STEP 2.

---

### STEP 2: Resolve Input and Working Description

**EXECUTE NOW**: Resolve the input to a working description used for naming the branch and PR.

**Task mode** (`input_mode="task"`):
```bash
# Define cslib project paths
CSLIB_DIR="/home/benjamin/Projects/cslib"
CSLIB_STATE="$CSLIB_DIR/specs/state.json"

# Generate a session ID for status transitions later
session_id="sess_$(date +%s)_$(head -c8 /dev/urandom | xxd -p 2>/dev/null || date +%N)"

# Read task metadata from state.json
task_name=$(jq -r --argjson num "$input_value" \
  '.active_projects[] | select(.project_number == $num) | .project_name' \
  "$CSLIB_STATE" 2>/dev/null)
task_status=$(jq -r --argjson num "$input_value" \
  '.active_projects[] | select(.project_number == $num) | .status' \
  "$CSLIB_STATE" 2>/dev/null)

# Validate task status: warn if not pr_ready
if [ "$task_status" != "pr_ready" ] && [ -n "$task_status" ] && [ "$task_status" != "null" ]; then
  echo "Warning: Task $input_value is in [$task_status] status, not [PR READY]."
  echo "This task may not have a pr-description.md prepared by skill-pr-implementation."
  # Ask user to continue anyway or abort
  # (Use AskUserQuestion or present options — continue will use fallback description generation)
fi

# Convert underscores to spaces for display
working_desc=$(echo "$task_name" | tr '_' ' ')
```
If not found, use `"task $input_value"` as `working_desc`.

```bash
# Compute pr-description.md path
task_num_padded=$(printf '%03d' "$input_value")
task_dir="$CSLIB_DIR/specs/${task_num_padded}_${task_name}"
pr_desc_path="$task_dir/pr-description.md"

# Load pr-description.md if it exists
if [ -f "$pr_desc_path" ]; then
  pr_body=$(cat "$pr_desc_path")
  pr_title=$(head -1 "$pr_desc_path" | sed 's/^# //')
  has_pr_description=true
  echo "Found pr-description.md: $pr_desc_path"
  echo "PR title from file: $pr_title"
else
  has_pr_description=false
  echo "Warning: pr-description.md not found at $pr_desc_path"
  echo "The description will be composed interactively (STEP 9)."
fi

# Read base_branch from state.json task metadata (defaults to "main")
base_branch=$(jq -r --argjson num "$input_value" \
  '.active_projects[] | select(.project_number == $num) | .base_branch // "main"' \
  "$CSLIB_STATE" 2>/dev/null)
base_branch="${base_branch:-main}"

# Stacked PR advisory: if pr_body mentions "stacked" but base_branch is "main"
if [ "$has_pr_description" = "true" ]; then
  if echo "$pr_body" | grep -qi "stacked" && [ "$base_branch" = "main" ]; then
    echo "Advisory: PR description mentions a stacked PR but base_branch is not set in task metadata."
    echo "Using --base main. If this PR should target a different branch, set base_branch in state.json."
  fi
fi
```

**Path mode** (`input_mode="path"`):
```bash
# Verify path exists
if [ -e "$input_value" ]; then
  working_desc="changes in $(basename $input_value)"
else
  echo "Warning: path '$input_value' not found"
  working_desc="changes to $(basename $input_value)"
fi
```

**Description mode** (`input_mode="description"`):
```
working_desc="$input_value"
```

Display:
```
Input Mode: {input_mode}
Working Description: {working_desc}
```

**On success**: **IMMEDIATELY CONTINUE** to STEP 3.

---

### STEP 3: Environment Check

**EXECUTE NOW**: Verify all required tools and git configuration are in place.

Run these checks in the CSLib project directory (`/home/benjamin/Projects/cslib`):

```bash
cd /home/benjamin/Projects/cslib

# Check gh CLI authentication
gh auth status 2>&1
AUTH_STATUS=$?

# Check git remotes
git remote -v 2>&1

# Verify we are in the cslib project
git remote get-url upstream 2>&1
```

Verify:
1. `gh auth status` exits 0 — if not, display:
   ```
   ERROR: gh CLI is not authenticated.
   Fix: Run `gh auth login` and follow the prompts.
   ```
   Then **STOP** — cannot continue without gh auth.

2. `origin` remote points to `benbrastmckie/cslib` (fork).
3. `upstream` remote points to `leanprover/cslib` (canonical repo).
   - If `upstream` is missing, display:
     ```
     ERROR: 'upstream' remote not configured.
     Fix: Run: git remote add upstream https://github.com/leanprover/cslib.git
     ```
     Then **STOP**.

4. Current directory contains `lakefile.toml` or `lakefile.lean` (CSLib project root).

Display summary:
```
Environment Check
=================
- gh CLI: authenticated
- origin: git@github.com:benbrastmckie/cslib.git
- upstream: https://github.com/leanprover/cslib.git
- Project: CSLib (lakefile found)
All checks passed.
```

**On success**: **IMMEDIATELY CONTINUE** to STEP 4.

---

### STEP 4: Sync with Upstream

**EXECUTE NOW**: Fetch latest changes from upstream to ensure the branch will be based on current main.

```bash
cd /home/benjamin/Projects/cslib

# Fetch upstream
git fetch upstream 2>&1
FETCH_STATUS=$?

if [ $FETCH_STATUS -eq 0 ]; then
  echo "Fetched upstream/main successfully."
  # Show how far ahead/behind we are
  git log --oneline HEAD..upstream/main 2>/dev/null | head -5
else
  echo "Warning: Could not fetch upstream. Proceeding with local state."
fi

# Show current branch
git branch --show-current
```

If currently on a feature branch (not `main`), note it but proceed — the PR branch will be
created from `upstream/main` regardless.

**On success**: **IMMEDIATELY CONTINUE** to STEP 5.

---

### STEP 5: Branch Creation

**EXECUTE NOW**: Propose a branch name and ask the user to confirm before creating it.

Generate the slug from `working_desc`:
```bash
# Create slug: lowercase, spaces to hyphens, remove special chars, max 40 chars
slug=$(echo "$working_desc" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | \
  sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | cut -c1-40)
proposed_branch="feat/$slug"
```

If `branch_override` was provided via `--branch`, use that instead.

Check if branch already exists:
```bash
cd /home/benjamin/Projects/cslib
local_exists=$(git branch --list "$proposed_branch" 2>/dev/null)
remote_exists=$(git ls-remote --heads origin "$proposed_branch" 2>/dev/null)
```

**Task mode** (`input_mode="task"`): If a `feat/` branch matching the task slug already exists
locally (as would be created by `skill-pr-implementation`), offer to reuse it:
```bash
if [ -n "$local_exists" ] || [ -n "$remote_exists" ]; then
  echo "Branch '$proposed_branch' already exists (created by skill-pr-implementation)."
  # Ask user to reuse existing branch or create a new one
fi
```

**Ask the user** via AskUserQuestion:
```json
{
  "question": "Create feature branch '{proposed_branch}' from upstream/main?",
  "header": "Branch Creation",
  "multiSelect": false,
  "options": [
    {"label": "Yes, create '{proposed_branch}'", "description": "Create this branch from upstream/main and switch to it"},
    {"label": "Reuse existing '{proposed_branch}'", "description": "Switch to the existing branch (if created by skill-pr-implementation)"},
    {"label": "Use a different name", "description": "Enter a custom branch name at the prompt"},
    {"label": "Cancel", "description": "Abort the PR workflow"}
  ]
}
```

- If **Yes**: proceed with `proposed_branch` (create new from upstream/main)
- If **Reuse existing**: switch to the branch without recreating: `git checkout "$proposed_branch"`
- If **Use a different name**: display "Enter branch name (format: type/description):" and read input from the conversation; use that as `branch_name`
- If **Cancel**: **STOP** — user aborted

If `--dry-run`: show what would happen and skip git commands.

Otherwise (creating new branch):
```bash
cd /home/benjamin/Projects/cslib
git checkout upstream/main -b "$branch_name" 2>&1
```

If branch already exists locally and user chose to create new, ask to delete and recreate or switch to existing.

Display:
```
Branch created: {branch_name}
Based on: upstream/main ({commit_hash})
```

**On success**: **IMMEDIATELY CONTINUE** to STEP 6.

---

### STEP 6: Stage Changes

**EXECUTE NOW**: Apply the relevant changes to the new feature branch.

**Task mode**:
```bash
cd /home/benjamin/Projects/cslib
# Show current git status — user is expected to have changes already staged
# or the task implementation has modified files in the CSLib project.
git status --short 2>&1
git diff --stat HEAD 2>&1
```
Display the diff summary. If no changes are detected, warn:
```
Warning: No changes detected on this branch.
Make sure you have modified CSLib files before running /pr.
Staged changes from your working copy will be committed.
```

**Path mode**:
```bash
cd /home/benjamin/Projects/cslib
# Stage the specified path
git add "$input_value" 2>&1
git status --short 2>&1
```

**Description mode**:
```bash
cd /home/benjamin/Projects/cslib
# Show git status — user must have already made changes
git status --short 2>&1
git diff --stat HEAD 2>&1
```
If no changes, display:
```
No staged or unstaged changes found.
Please make your changes to CSLib files first, then run /pr again.
```
**STOP** if no changes in description mode.

For all modes: list the changed files that will be included in the PR.

**Check for new files** (needed for Step 7 CI step 6):
```bash
git status --porcelain | grep '^[?A]' | grep '\.lean$' | head -20
```
Store whether new `.lean` files exist (`has_new_lean_files`).

**On success**: **IMMEDIATELY CONTINUE** to STEP 7.

---

### STEP 7: Run CI Pipeline

**EXECUTE NOW**: Run all 7 CI steps in order. Report each result. Offer auto-fix on failure where available.

Set working directory to CSLib project:
```bash
cd /home/benjamin/Projects/cslib
```

Display header:
```
CI Pipeline
===========
Running 7-step verification pipeline...
```

#### CI Step 1: lake build

```bash
lake build 2>&1
```

- Pass: `[PASS] lake build`
- Fail: Show output. **Ask user** via AskUserQuestion:
  ```json
  {
    "question": "lake build failed. How would you like to proceed?",
    "header": "CI Step 1 Failed: lake build",
    "multiSelect": false,
    "options": [
      {"label": "Fix errors and re-run CI", "description": "Fix compilation errors, then restart from CI Step 1"},
      {"label": "Abort PR", "description": "Stop the PR workflow and return to working branch"}
    ]
  }
  ```
  - Fix and re-run: **RESTART STEP 7** from CI Step 1 after user indicates fixes are done
  - Abort: `git checkout main 2>&1` then **STOP**

#### CI Step 2: lake exe checkInitImports

```bash
lake exe checkInitImports 2>&1
```

- Pass: `[PASS] lake exe checkInitImports`
- Fail: Show output explaining which files are missing `import Cslib.Init`. **Ask user** same pattern as Step 1.

#### CI Step 3: lake lint

```bash
lake lint 2>&1
```

- Pass: `[PASS] lake lint`
- Fail: Show output. **Ask user** same pattern as Step 1.

#### CI Step 4: lake exe lint-style

```bash
lake exe lint-style 2>&1
LINT_STYLE_STATUS=$?
```

- Pass: `[PASS] lake exe lint-style`
- Fail: Show output. **Ask user** via AskUserQuestion:
  ```json
  {
    "question": "lake exe lint-style found issues. Auto-fix?",
    "header": "CI Step 4: lint-style Issues",
    "multiSelect": false,
    "options": [
      {"label": "Yes, run --fix and continue", "description": "Run lake exe lint-style --fix to auto-fix style issues, then re-verify"},
      {"label": "Fix manually and re-run CI", "description": "Fix style issues manually, then restart CI pipeline"},
      {"label": "Abort PR", "description": "Stop the PR workflow"}
    ]
  }
  ```
  - Auto-fix:
    ```bash
    lake exe lint-style --fix 2>&1
    lake exe lint-style 2>&1  # re-verify
    ```
    - If still failing: show output, ask to fix manually or abort
  - Manual fix: **RESTART STEP 7** after user indicates fixes are done
  - Abort: `git checkout main` then **STOP**

#### CI Step 5: lake test

```bash
lake test 2>&1
```

- Pass: `[PASS] lake test`
- Fail: Show output. **Ask user** same pattern as Step 1 (fix and re-run or abort).

#### CI Step 6: lake exe mk_all --module (conditional)

Only run if `has_new_lean_files` is true (new `.lean` files were added):

```bash
lake exe mk_all --module 2>&1
```

- Pass: `[PASS] lake exe mk_all --module`
- Skipped (no new files): `[SKIP] lake exe mk_all --module (no new files detected)`
- Fail: Show output. **Ask user** same pattern as Step 1.

#### CI Step 7: lake shake

```bash
lake shake --add-public --keep-implied --keep-prefix 2>&1
SHAKE_STATUS=$?
```

- Pass: `[PASS] lake shake`
- Fail: Show output. **Ask user** via AskUserQuestion:
  ```json
  {
    "question": "lake shake found import issues. Auto-fix?",
    "header": "CI Step 7: lake shake Issues",
    "multiSelect": false,
    "options": [
      {"label": "Yes, run --fix and continue", "description": "Run lake shake with --fix to minimize imports automatically"},
      {"label": "Fix manually and re-run CI", "description": "Fix import issues manually, then restart CI pipeline"},
      {"label": "Abort PR", "description": "Stop the PR workflow"}
    ]
  }
  ```
  - Auto-fix:
    ```bash
    lake shake --add-public --keep-implied --keep-prefix --fix 2>&1
    lake shake --add-public --keep-implied --keep-prefix 2>&1  # re-verify
    ```
    - If still failing: show output, ask to fix manually or abort
  - Manual fix: **RESTART STEP 7** after user indicates done
  - Abort: `git checkout main` then **STOP**

#### CI Summary

Display:
```
CI Pipeline Results
===================
[PASS] lake build
[PASS] lake exe checkInitImports
[PASS] lake lint
[PASS] lake exe lint-style
[PASS] lake test
[PASS/SKIP] lake exe mk_all --module
[PASS] lake shake

All CI checks passed!
```

**On success**: **IMMEDIATELY CONTINUE** to STEP 8.

---

### STEP 8: Select PR Title

**EXECUTE NOW**: Guide the user in composing a conventional commit PR title.

**Task mode** (`input_mode="task"`) — when `has_pr_description` is true:
The title was already extracted from `pr-description.md` in STEP 2. Skip the 3-step interactive
flow and present the loaded title for approval instead:

Display:
```
PR title from pr-description.md:
  {pr_title}
```

**Ask user** via AskUserQuestion:
```json
{
  "question": "Use this PR title from pr-description.md?\n\n{pr_title}",
  "header": "PR Title: Confirm or Override",
  "multiSelect": false,
  "options": [
    {"label": "Yes, use this title", "description": "Proceed with the title from pr-description.md"},
    {"label": "Override with custom title", "description": "Enter a custom PR title in the conversation"}
  ]
}
```

- If **Yes**: `pr_title` is already set — proceed directly to STEP 9
- If **Override**: display "Enter the full PR title (e.g., 'feat(Logics): prove completeness for K'):"
  and read the user's next message as `pr_title`

Store `pr_title` and **IMMEDIATELY CONTINUE** to STEP 9.

---

**Path mode or Description mode** (or task mode when `has_pr_description` is false):
Fall through to the full interactive 3-step title selection:

Display the prefix options and **Ask user** via AskUserQuestion:
```json
{
  "question": "Select the conventional commit prefix for your PR title:",
  "header": "PR Title — Step 1 of 3: Prefix",
  "multiSelect": false,
  "options": [
    {"label": "feat", "description": "New features, formalizations, definitions, theorems"},
    {"label": "fix", "description": "Bug fixes, incorrect proofs, broken imports"},
    {"label": "doc", "description": "Documentation improvements, docstring additions"},
    {"label": "style", "description": "Formatting, linting fixes, style conformance only"},
    {"label": "refactor", "description": "Code restructuring without behavior change"},
    {"label": "test", "description": "Adding or fixing tests in CslibTests/"},
    {"label": "chore", "description": "Build system, CI, dependency updates"},
    {"label": "perf", "description": "Performance improvements (compilation speed, proof size)"}
  ]
}
```

Store the selected prefix as `pr_prefix` (e.g., `feat`).

Then ask for optional area qualifier via AskUserQuestion:
```json
{
  "question": "Add an optional area qualifier? (e.g., Logics, Foundations, Languages/Boole)",
  "header": "PR Title — Step 2 of 3: Area (Optional)",
  "multiSelect": false,
  "options": [
    {"label": "No area qualifier", "description": "Title will be: {pr_prefix}: {description}"},
    {"label": "Logics", "description": "feat(Logics): ..."},
    {"label": "Foundations", "description": "feat(Foundations): ..."},
    {"label": "Languages", "description": "feat(Languages): ..."},
    {"label": "Bimodal", "description": "feat(Bimodal): ..."},
    {"label": "Custom area", "description": "Enter a custom area qualifier in the conversation"}
  ]
}
```

Store the area as `pr_area` (empty string if "No area qualifier").

Then ask the user to provide the description text:

Display:
```
Compose the PR title description.
Prefix chosen: {pr_prefix}
Area: {pr_area or "(none)"}

Suggested from your input: "{working_desc}"

Please type the final description text (e.g., "prove completeness for modal logic K"):
```

Read the description from the user's next message. If no custom description provided, use
the suggested text from `working_desc`.

Compose the final title:
- With area: `{pr_prefix}({pr_area}): {description}`
- Without area: `{pr_prefix}: {description}`

Display and confirm via AskUserQuestion:
```json
{
  "question": "Use this PR title?\n\n{composed_title}",
  "header": "PR Title — Step 3 of 3: Confirm",
  "multiSelect": false,
  "options": [
    {"label": "Yes, use this title", "description": "Proceed with the composed title"},
    {"label": "Start over", "description": "Redo the title selection from the beginning"}
  ]
}
```

If "Start over": **RESTART STEP 8**.

Store `pr_title = composed_title`.

**On success**: **IMMEDIATELY CONTINUE** to STEP 9.

---

### STEP 9: Compose PR Description

**EXECUTE NOW**: Build the PR description from pr-description.md (task mode) or the template (other modes).

**Task mode** (`input_mode="task"`) — when `has_pr_description` is true:
The body was loaded from `pr-description.md` in STEP 2. Display it and ask for approval:

Display:
```
PR description from pr-description.md ({pr_desc_path}):
────────────────────────────────────────────────────────
{first 20 lines of pr_body}
...
```

**Ask user** via AskUserQuestion:
```json
{
  "question": "Review the PR description loaded from pr-description.md:",
  "header": "PR Description",
  "multiSelect": false,
  "options": [
    {"label": "Approve — use this description", "description": "Proceed with the content from pr-description.md"},
    {"label": "Edit summary section", "description": "Provide a custom summary in the conversation, keep the rest"},
    {"label": "Edit AI disclosure", "description": "Customize the AI disclosure section"},
    {"label": "Replace entirely", "description": "Type a complete custom description in the conversation"}
  ]
}
```

- Approve: proceed with `pr_body = pr_body` (already loaded)
- Edit summary: read user's next message as the new summary; replace the `## Summary` section
- Edit AI disclosure: read user's next message as the new disclosure; replace `## AI Disclosure`
- Replace entirely: read user's next message as the full `pr_body`

**On success**: **IMMEDIATELY CONTINUE** to STEP 10.

---

**Path mode, Description mode, or Task mode when `has_pr_description` is false**:
Fall through to template-based description generation:

Collect the list of changed files:
```bash
cd /home/benjamin/Projects/cslib
git diff --name-only HEAD 2>&1 | head -30
git diff --cached --name-only 2>&1 | head -30
```

Compose draft PR description using the CSLib canonical format:

```markdown
## Summary

{working_desc — 2-4 sentences about what this PR adds/changes, naming key constructs}

## Context

{Include this section only if applicable:
- Stacked on another PR: "This PR is **stacked on #{NNN}** ("{PR title}"), which introduces {what it provides}. Please review/merge #{NNN} first."
- Zulip discussion exists: "**Zulip topic**: [{channel/topic}]({URL})"
- Literature motivation: full citation (Author, Year, *Title*. Publisher.)}

## File-by-file change summary

{git diff --stat output in a code fence}

### {filename.lean} (+N, -M)
- {bullet points describing key changes in this file}

## AI Disclosure

This PR was prepared with the assistance of Claude Code (Anthropic). The AI tool was used for:
- Drafting and extracting files from a development branch to create a clean PR branch
- Running CI verification commands
- Drafting this PR description

All Lean code was written by the author (Benjamin Brast-McKie) and verified to compile cleanly on the PR branch.
```

Display the draft to the user and ask via AskUserQuestion:
```json
{
  "question": "Review the PR description draft and choose an action:",
  "header": "PR Description",
  "multiSelect": false,
  "options": [
    {"label": "Approve — use this description", "description": "Proceed with the auto-generated description"},
    {"label": "Edit summary section", "description": "Provide a custom summary in the conversation, keep the rest"},
    {"label": "Edit AI disclosure", "description": "Customize the AI disclosure section"},
    {"label": "Replace entirely", "description": "Type a complete custom description in the conversation"}
  ]
}
```

- Approve: proceed with `pr_body = draft_description`
- Edit summary: read user's next message as the new summary; replace the `## Summary` section
- Edit AI disclosure: read user's next message as the new disclosure; replace `## AI Disclosure`
- Replace entirely: read user's next message as the full `pr_body`

**On success**: **IMMEDIATELY CONTINUE** to STEP 10.

---

### STEP 10: Commit, Push, and Create PR

**EXECUTE NOW**: Commit staged changes, push to origin, and create the PR against upstream.

First, commit any staged or unstaged changes on the branch:
```bash
cd /home/benjamin/Projects/cslib

# Check if there are any changes to commit
git status --porcelain 2>&1
```

If there are uncommitted changes:
```bash
# Stage all changes
git add -A 2>&1

# Commit with descriptive message
git commit -m "$pr_title" 2>&1
```

Display the commit summary.

Then show the PR summary to the user before submission:
```
PR Submission Summary
=====================
Title: {pr_title}
Branch: {branch_name} -> leanprover/cslib {base_branch}
Draft: {true/false}
Changed files:
  {list of changed files}

CI: All 7 steps passed

Description preview:
{first 10 lines of pr_body}
...
```

**Ask user** for final approval via AskUserQuestion:
```json
{
  "question": "Submit this PR to leanprover/cslib?",
  "header": "Submit PR",
  "multiSelect": false,
  "options": [
    {"label": "Yes, submit the PR", "description": "Push branch and create PR on GitHub"},
    {"label": "Submit as draft", "description": "Create as draft PR (not ready for review)"},
    {"label": "Cancel — do not submit", "description": "Abort without pushing or creating PR"}
  ]
}
```

- Yes or Submit as draft: proceed (override `is_draft` if user selected draft)
- Cancel: **STOP** — inform user the branch exists locally and can be submitted later

If `--dry-run`: show what would execute without running:
```
[DRY RUN] Would execute:
  git push -u origin {branch_name}
  gh pr create --base {base_branch} --repo leanprover/cslib \
    --title "{pr_title}" \
    --body "..." \
    {--draft if draft}
```
Then **STOP**.

Otherwise:
```bash
cd /home/benjamin/Projects/cslib

# Push to origin
git push -u origin "$branch_name" 2>&1
PUSH_STATUS=$?

if [ $PUSH_STATUS -ne 0 ]; then
  echo "ERROR: Push failed. See output above."
  # STOP and report error
fi

# Create PR
if [ "$is_draft" = "true" ]; then
  gh pr create \
    --base "$base_branch" \
    --repo leanprover/cslib \
    --title "$pr_title" \
    --body "$pr_body" \
    --draft 2>&1
else
  gh pr create \
    --base "$base_branch" \
    --repo leanprover/cslib \
    --title "$pr_title" \
    --body "$pr_body" 2>&1
fi
```

Capture and display the PR URL from `gh pr create` output.

Display:
```
PR Created Successfully!
========================
URL: {pr_url}
Title: {pr_title}
Branch: {branch_name}
Status: {Open/Draft}

Next: Monitor the PR at {pr_url}
CI will run automatically on GitHub Actions.
```

**On success**: **IMMEDIATELY CONTINUE** to STEP 10b (if task mode) or STEP 11 (otherwise).

---

### STEP 10b: Transition Task Status to Completed (Task Mode Only)

**EXECUTE NOW** (task mode only — skip if `input_mode` is not "task"):

After a successful PR submission, transition the task from `[PR READY]` to `[COMPLETED]` in the
cslib project:

```bash
cd "$CSLIB_DIR"
if ! bash .claude/scripts/update-task-status.sh postflight "$input_value" pr_ready "$session_id" 2>/dev/null; then
  echo "Note: Could not update task $input_value status to [COMPLETED]."
  echo "The update-task-status.sh script may not support pr_ready yet."
  echo "Manually update task $input_value to [COMPLETED] in:"
  echo "  $CSLIB_DIR/specs/state.json"
else
  echo "Task $input_value transitioned to [COMPLETED]."
fi
```

Display:
```
Task Status Update
==================
Task {input_value} -> [COMPLETED]
(If update failed, update manually per the note above.)
```

**On success**: **IMMEDIATELY CONTINUE** to STEP 11.

---

### STEP 11: Offer Merge-Back

**EXECUTE NOW**: After PR submission, offer to sync origin/main with upstream/main.

**Ask user** via AskUserQuestion:
```json
{
  "question": "Merge upstream/main back into origin/main to stay in sync?",
  "header": "Sync Origin with Upstream",
  "multiSelect": false,
  "options": [
    {"label": "Yes, sync now", "description": "Fetch upstream/main and merge into local main, then push to origin"},
    {"label": "No, skip", "description": "Leave origin/main as-is; sync manually later"}
  ]
}
```

If **Yes**:
```bash
cd /home/benjamin/Projects/cslib

# Fetch latest upstream
git fetch upstream 2>&1

# Check for potential conflicts before merging
git log --oneline origin/main..upstream/main | head -10

# Switch to main
git checkout main 2>&1

# Check for conflicts
git merge --no-commit --no-ff upstream/main 2>&1
MERGE_CHECK=$?

if [ $MERGE_CHECK -ne 0 ]; then
  echo "WARNING: Merge conflicts detected. Aborting auto-merge."
  git merge --abort 2>&1
  echo ""
  echo "Resolve conflicts manually:"
  echo "  git checkout main"
  echo "  git merge upstream/main"
  echo "  # resolve conflicts"
  echo "  git push origin main"
else
  # No conflicts — complete the merge
  git merge --abort 2>&1  # abort the no-commit check
  git merge upstream/main 2>&1
  git push origin main 2>&1
  echo ""
  echo "Sync complete: origin/main is now up to date with upstream/main."
fi
```

If conflict detected, display instructions and **STOP** gracefully.
If no conflict: display success and **STOP**.

If **No**: display:
```
Sync skipped. To sync later:
  git checkout main
  git fetch upstream
  git merge upstream/main
  git push origin main
```

**STOP** — workflow complete.

---

## Output Examples

### Successful PR Submission

```
CI Pipeline Results
===================
[PASS] lake build
[PASS] lake exe checkInitImports
[PASS] lake lint
[PASS] lake exe lint-style
[PASS] lake test
[SKIP] lake exe mk_all --module (no new files detected)
[PASS] lake shake

PR Created Successfully!
========================
URL: https://github.com/leanprover/cslib/pull/42
Title: feat(Logics): prove completeness for modal logic K
Branch: feat/prove-completeness-modal-logic-k
Status: Open
```

### Dry-Run Output

```
[DRY RUN] PR Workflow Preview
==============================
Branch: feat/prove-completeness-modal-logic-k
Based on: upstream/main

CI would run: lake build, checkInitImports, lint, lint-style, test, shake
PR title: feat(Logics): prove completeness for modal logic K
PR target: leanprover/cslib (main branch)
Draft: false

No changes made (dry-run mode).
```

## Error Recovery

### gh CLI Not Authenticated

```
Error: gh CLI is not authenticated.
Fix: Run `gh auth login` and complete OAuth flow.
Then re-run /pr to start the workflow.
```

### Push Rejected (Force Required)

```
Error: Push to origin rejected.
This usually means the branch exists on origin with different history.

Options:
  1. Delete remote branch and re-push:
     git push origin --delete {branch_name}
     git push -u origin {branch_name}

  2. Force push (if you know this is safe):
     git push --force-with-lease origin {branch_name}
```

### CI Failure Guidance

When a CI step fails, the command shows the full output and offers:
- Auto-fix (for `lint-style` and `shake` only)
- Manual fix with re-run from the same step
- Abort and return to main branch

### Branch Already Exists

If the branch already exists locally or on origin, the command will:
1. Warn the user
2. Offer to delete and recreate from upstream/main
3. Or switch to the existing branch and continue from there

## Notes

- PRs always target `leanprover/cslib` (upstream), never `benbrastmckie/cslib` (fork)
- The CSLib fork model: `origin` = your fork, `upstream` = leanprover/cslib
- AI disclosure is always included in the PR body per CSLib and Mathlib policy
- For major changes (new abstractions, cross-cutting refactors), coordinate on Zulip first
- `lake exe mk_all --module` is only run when new `.lean` files are detected in the diff
