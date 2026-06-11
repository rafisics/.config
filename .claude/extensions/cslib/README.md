# CSLib Extension

CSLib Lean 4 computer science library formalization support. Provides research and implementation agents for CSLib contributions, inheriting `lean-lsp` MCP tools from the lean extension for live goal inspection, proof search, and Mathlib/CSLib lookup.

## Overview

| Task Type | Research | Plan | Implementation |
|-----------|----------|------|----------------|
| `cslib` | skill-cslib-research | skill-planner | skill-cslib-implementation |

The extension routes `cslib` task types through dedicated agents that enforce CSLib coding conventions, use the CI verification pipeline, and follow the project's reuse-first and proof-readability principles from CONTRIBUTING.md.

## Installation

Loaded via the extension picker. Once loaded, `cslib` becomes a recognized task type. The lean extension is auto-loaded as a dependency, providing `lean-lsp` MCP access.

## Architecture

    cslib/
    +-- manifest.json              # Extension configuration
    +-- EXTENSION.md               # CLAUDE.md merge content
    +-- index-entries.json         # Context discovery entries
    +-- README.md                  # This file
    |
    +-- agents/
    |   +-- cslib-research-agent.md       # CSLib formalization research
    |   +-- cslib-implementation-agent.md  # CSLib proof implementation
    |
    +-- skills/
    |   +-- skill-cslib-research/   # Research skill wrapper
    |   +-- skill-cslib-implementation/ # Implementation skill wrapper
    |
    +-- commands/                  # (none -- uses standard /research, /plan, /implement)
    |
    +-- rules/
    |   +-- cslib.md               # CSLib coding conventions (auto-applied to *.lean)
    |
    +-- context/
        +-- project/
            +-- cslib/
                +-- domain/        # CSLib architecture, CONTRIBUTING standards, notation
                +-- patterns/      # Proof structure, module organization, reuse-first
                +-- standards/     # CI pipeline, PR conventions, mathlib style
                +-- tools/         # lake commands, linters, checkInitImports, mk_all

## Skill-Agent Mapping

| Skill | Agent | Model | Purpose |
|-------|-------|-------|---------|
| skill-cslib-research | cslib-research-agent | opus | CSLib/Mathlib research with lean-lsp MCP |
| skill-cslib-implementation | cslib-implementation-agent | sonnet | CSLib proof implementation with CI verification |

## Language Routing

| Task Type | Research Skill | Implementation Skill | Tools |
|-----------|----------------|---------------------|-------|
| `cslib` | skill-cslib-research | skill-cslib-implementation | WebSearch, WebFetch, Read, Write, Edit, Bash(lake), lean-lsp MCP |

## CI Verification Pipeline

CSLib implementation agent runs the full CI suite after edits:

    lake test                                             # Run CslibTests suite
    lake exe checkInitImports                             # Verify Cslib.Init imports
    lake exe lint-style                                   # Style linting
    lake shake --add-public --keep-implied --keep-prefix  # Dependency analysis

## References

- [CSLib Repository](https://github.com/leanprover-community/cslib) (or local: `/home/benjamin/Projects/cslib/`)
- [CSLib CONTRIBUTING.md](../../../../../../../Projects/cslib/CONTRIBUTING.md)
- [Lean 4 Documentation](https://leanprover.github.io/lean4/doc/)
- [Mathlib](https://leanprover-community.github.io/mathlib4_docs/)
