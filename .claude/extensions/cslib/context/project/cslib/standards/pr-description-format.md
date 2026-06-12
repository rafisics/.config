# CSLib PR Description Format

Canonical format for CSLib pull request descriptions. Based on established patterns
from the cslib project PR history (PRs #635, #637, and subsequent sub-PRs).

## Required Sections

All CSLib PRs must include these sections, in this order:

### 1. Title (H1 heading)

The PR title as the document heading:

```
# {conventional commit title}
```

The conventional commit title uses the format from `pr-conventions.md`:
```
{feat|fix|doc|style|refactor|test|chore|perf}[({area})]: {description}
```

Examples:
```
# feat(Logics/Temporal): temporal logic formula type with primitives and derived operators
# refactor: Proposition type to Lukasiewicz convention
# fix(Foundations): correct substitution lemma in HasSubstitution
```

### 2. Summary

2-4 sentences describing what the PR adds or changes. Name the key types, theorems,
modules, or definitions introduced. For large PRs, include scope (N files, ~M lines).

```markdown
## Summary

{2-4 sentences. Name key constructs. State scope for large PRs.}
```

### 3. Context / Motivation (when applicable)

Include when any of the following apply:
- The PR is stacked on another unmerged PR
- There is a relevant Zulip discussion
- The design choice requires literature support

```markdown
## Context

{Stacked PR declaration:}
This PR is **stacked on #{NNN}** ("{PR title}"), which introduces {what it provides}.
{What this PR needs from that PR.} Please review/merge #{NNN} first.

{Zulip link:}
**Zulip topic**: [{channel/topic description}]({URL})

{Literature references:}
{Author, A. & Author, B. (year). *Title*. Publisher. {Specific chapter/section if relevant.}}
```

### 4. File-by-file change summary

Always present. Shows the git diff --stat followed by per-file bullet summaries.

````markdown
## File-by-file change summary

{Paste git diff --stat output in a code fence:}
```
 File1.lean   | N ++++++++++++
 File2.lean   | M +++---
 N files changed, X insertions(+), Y deletions(-)
```

### {File1.lean} (+N[, -M] [, NEW])

- {Bullet describing the key change in this file}
- {Another key change}

### {File2.lean} (+N, -M)

- {Bullet describing the key change}
````

For large PRs with many files (10+), use a markdown table instead of per-file bullets:

```markdown
| File | Lines | Role |
|------|------:|------|
| `Path/To/File.lean` | N | Brief role description |
```

### 5. AI Disclosure (always last)

Required for all CSLib PRs per the Mathlib AI usage policy. Always the last section.

```markdown
## AI Disclosure

This PR was prepared with the assistance of Claude Code (Anthropic). The AI tool was used for:
- Drafting and extracting files from a development branch to create a clean PR branch
- Running CI verification commands
- Drafting this PR description

All Lean code was written by the {author(s) — names} and verified to compile cleanly on the PR branch.
```

Short variant (for smaller PRs):

```markdown
## AI Disclosure

This PR was prepared with the assistance of Claude Code (Anthropic), used for drafting/extracting
files from a development branch, running CI verification commands, and drafting this description.
All Lean code was written by the author ({name}) and verified to compile on the PR branch.
```

---

## Optional Sections

These sections appear in some PRs but are not required:

### Design Rationale

Use for novel design decisions that require explanation. Name the section after the specific
design question:

```markdown
## Why {X} as the primitives
## Design: {component} architecture
## Argument convention: {name}
```

Include when:
- The primitive/representation choice is non-obvious and needs justification
- Literature references support the design
- The choice will affect all downstream PRs

### Dependency Graph

For large PRs with complex import structures:

````markdown
## Dependency Graph

```
ModuleA
    +-- ModuleB
        +-- ModuleC
```
````

### Verification (large PRs only)

Use only for large PRs to document that sorry-free verification was performed.
Not a checklist — state results:

```markdown
## Verification

- `lake build`: 0 errors (N jobs)
- `grep -rn "sorry"`: 0 hits across all contributed files
- CI validation suite passed: `lake test`, `lake shake`, `lake exe checkInitImports`, `lake lint`, `lake exe lint-style`
```

---

## What NOT to Include

**No CI checklist in the PR body.** Do not add:
```markdown
## CI
- [ ] `lake build` passes
- [ ] `lake lint` passes
```

CI runs automatically on GitHub Actions after the PR is submitted. Including a self-reported
checklist in the body is redundant and the boxes are written before CI has actually run.
The `/pr` command verifies CI locally before submission; that verification is not claimed
in the PR description itself.
