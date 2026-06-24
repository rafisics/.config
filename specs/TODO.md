---
next_project_number: 771
---

# TODO

## Task Order

*Updated 2026-06-24. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,767 | -- | agent-system, Terminal UI, Email Integration |
| 2 | 768 | 767 | agent-system |
| 3 | 769 | 768 | agent-system |
| 4 | 770 | 769 | agent-system |

**Grouped by Topic** (indented = depends on parent):

### Agent System

767 [NOT STARTED] — Make --hard mode a first-class CORE capability so core hard agent
  └─ 768 [NOT STARTED] — Implement the --hard routing behavior that CLAUDE.md (Routing Mec
    └─ 769 [NOT STARTED] — Add a validation guard (extend .claude/scripts/check-extension-do
      └─ 770 [NOT STARTED] — Re-deploy/propagate the corrected core hard agents + skills from 

### Terminal UI

87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Email Integration

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him

## Tasks

### 770. Re-deploy/propagate corrected core hard pieces to installed projects and sync CLAUDE.md docs
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 767, Task 768, Task 769

**Description**: Re-deploy/propagate the corrected core hard agents + skills from the canonical source (.claude/extensions/core/) to already-installed projects (e.g. BimodalLogic, which maintains its own .claude/extensions/core/ and triggered the original Agent type planner-hard-agent not found error when running /orchestrate 305 --hard --lit). Verify install-extension.sh symlinks the now-present core hard agent files and skill dirs into deployed .claude/agents/ and .claude/skills/. Sync the CLAUDE.md merge-source (.claude/extensions/core/merge-sources/claudemd.md) Hard Mode / Routing Mechanism sections to match the actual implemented behavior from task 768. Run the doc-lint guard from task 769 to confirm clean. Depends on 767, 768, 769.

---

### 769. Add manifest-vs-disk and routing-target consistency guard to doc-lint
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 767, Task 768

**Description**: Add a validation guard (extend .claude/scripts/check-extension-docs.sh or add a manifest-vs-disk consistency script) that catches this class of bug: (1) skill directory present on disk under an extension skills/ dir but NOT listed in provides.skills; (2) any skill named in routing OR routing_hard that has no corresponding skill on disk / not in provides; (3) any -hard fallback target (skill -> agent mapping) that has no declared+present agent file. check-extension-docs.sh currently validates that provides.agents/provides.skills files exist on disk and that non-routing_exempt extensions with skills declare a routing block, but it does NOT validate routing_hard targets nor that routing targets resolve to deployed agents. Make the check exit non-zero on violations so CI catches regressions. Depends on 767 (declarations to validate) and 768 (routing_hard semantics to validate against).

---

### 768. Implement and standardize routing_hard resolution and core/extension composition model
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 767

**Description**: Implement the --hard routing behavior that CLAUDE.md (Routing Mechanism / Hard Mode sections) documents but which command-route-skill.sh does NOT currently implement: the script as written has no 4th effort_flag argument, no routing_hard lookup, and no -hard append fallback. Add (a) a 4th effort_flag arg, (b) routing_hard.$operation.$task_type lookup across extension manifests, (c) the documented fallback of appending -hard to the resolved core skill name when the candidate skill .claude/skills/${skill}-hard/SKILL.md exists, with stderr note + graceful fallback to standard skill otherwise. Define and document the extension composition model for routing_hard: extension routing_hard OVERRIDES core routing_hard (precedence), and core hard skills/agents are guaranteed present so extensions can reference them (cslib/manifest.json routing_hard already references skill-planner-hard, skill-researcher-hard, skill-implementer-hard for the pr task type). Ensure the fallback never resolves to an undeclared/undeployed agent. Depends on 767 (core hard pieces must exist first).

---

### 767. Make core hard agents + skills first-class in core extension source
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Make --hard mode a first-class CORE capability so core hard agents/skills deploy to every project that installs the core extension. Author/move the hard agent FILES (planner-hard-agent.md, general-research-hard-agent.md, general-implementation-hard-agent.md) from the deployed tree .claude/agents/ into the canonical extension source .claude/extensions/core/agents/ (they currently exist only in the deployed tree). Add all core hard agents AND hard skills to provides.agents / provides.skills in .claude/extensions/core/manifest.json. The hard skill directories skill-implementer-hard, skill-planner-hard, skill-researcher-hard already exist under .claude/extensions/core/skills/ but are NOT listed in provides.skills; verify whether skill-orchestrate-hard exists in the core source (it exists in the deployed .claude/skills/) and author it into core/skills/ if missing, then list it too. Add a core routing_hard map covering core task types (general, meta, markdown) for research/plan/implement, consistent with how lean/cslib declare theirs. Foundational task: 768, 769, 770 depend on this.

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
