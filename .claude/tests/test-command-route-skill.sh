#!/usr/bin/env bash
# test-command-route-skill.sh — Shell-level resolver tests for command-route-skill.sh
#
# USAGE:
#   bash .claude/tests/test-command-route-skill.sh
#
# EXITS:
#   0 — All tests pass
#   1 — One or more tests failed
#
# NOTES:
#   - Tests must be run from the project root (where .claude/ is a direct child)
#   - The script sources command-route-skill.sh in subshells to avoid variable leakage
#   - Assertions: SKILL_NAME value, exit/source status, and stderr content

set -euo pipefail

PASS=0
FAIL=0
FAILURES=""

# ---------------------------------------------------------------------------
# Helper: run_test <test_name> <expected_skill> [expected_stderr_pattern]
#
# Accepts positional args for the route script:
#   $ROUTE_OP, $ROUTE_TYPE, $ROUTE_DEFAULT, $ROUTE_EFFORT (optional)
# ---------------------------------------------------------------------------
run_test() {
  local test_name="$1"
  local expected_skill="$2"
  local expected_stderr="${3:-}"
  local op="${ROUTE_OP:-implement}"
  local task_type="${ROUTE_TYPE:-general}"
  local default="${ROUTE_DEFAULT:-skill-implementer}"
  local effort="${ROUTE_EFFORT:-}"

  # Run in subshell; capture stdout, stderr, and exit status
  local actual_skill stderr_output
  stderr_output=$(mktemp)
  actual_skill=$(
    (
      source .claude/scripts/command-route-skill.sh "$op" "$task_type" "$default" "${effort}" 2>"$stderr_output"
      echo "$SKILL_NAME"
    )
  )
  local source_exit=$?
  local stderr_content
  stderr_content=$(cat "$stderr_output")
  rm -f "$stderr_output"

  # Assert: source succeeded (non-fatal resolution)
  if [ "$source_exit" -ne 0 ]; then
    FAIL=$((FAIL + 1))
    FAILURES="$FAILURES\n  FAIL [$test_name]: source exited with status $source_exit (expected 0)"
    return
  fi

  # Assert: SKILL_NAME matches expected
  if [ "$actual_skill" = "$expected_skill" ]; then
    echo "  PASS [$test_name]: SKILL_NAME=$actual_skill"
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILURES="$FAILURES\n  FAIL [$test_name]: expected SKILL_NAME=$expected_skill, got=$actual_skill"
  fi

  # Assert: stderr pattern (if expected)
  if [ -n "$expected_stderr" ]; then
    if echo "$stderr_content" | grep -qF "$expected_stderr"; then
      echo "  PASS [$test_name/stderr]: found expected note"
    else
      FAIL=$((FAIL + 1))
      FAILURES="$FAILURES\n  FAIL [$test_name/stderr]: expected stderr to contain '$expected_stderr', got: '$stderr_content'"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Test Suite
# ---------------------------------------------------------------------------
echo "Running command-route-skill.sh resolver tests..."
echo ""

# --- Standard-mode regression (no effort_flag) ---
echo "=== Standard-mode regression ==="

ROUTE_OP="implement" ROUTE_TYPE="meta" ROUTE_DEFAULT="skill-implementer" ROUTE_EFFORT=""
run_test "std: implement/meta -> skill-implementer" "skill-implementer"

ROUTE_OP="research" ROUTE_TYPE="general" ROUTE_DEFAULT="skill-researcher" ROUTE_EFFORT=""
run_test "std: research/general -> skill-researcher" "skill-researcher"

ROUTE_OP="plan" ROUTE_TYPE="general" ROUTE_DEFAULT="skill-planner" ROUTE_EFFORT=""
run_test "std: plan/general -> skill-planner" "skill-planner"

# Extension standard routing (cslib should route to cslib skill, not implementer)
ROUTE_OP="implement" ROUTE_TYPE="cslib" ROUTE_DEFAULT="skill-implementer" ROUTE_EFFORT=""
run_test "std: implement/cslib -> cslib extension routing" "skill-cslib-implementation"

echo ""

# --- Hard-mode: core routing_hard ---
echo "=== Hard-mode: core routing_hard ==="

# (implement, meta, hard) -> skill-implementer-hard
ROUTE_OP="implement" ROUTE_TYPE="meta" ROUTE_DEFAULT="skill-implementer" ROUTE_EFFORT="hard"
run_test "hard: implement/meta -> skill-implementer-hard" "skill-implementer-hard"

# (plan, general, hard) -> skill-planner-hard
ROUTE_OP="plan" ROUTE_TYPE="general" ROUTE_DEFAULT="skill-planner" ROUTE_EFFORT="hard"
run_test "hard: plan/general -> skill-planner-hard" "skill-planner-hard"

# (research, meta, hard) -> skill-researcher-hard
ROUTE_OP="research" ROUTE_TYPE="meta" ROUTE_DEFAULT="skill-researcher" ROUTE_EFFORT="hard"
run_test "hard: research/meta -> skill-researcher-hard" "skill-researcher-hard"

echo ""

# --- Hard-mode: extension routing_hard overrides core ---
echo "=== Hard-mode: extension routing_hard overrides core ==="

# (research, cslib, hard) -> skill-cslib-research-hard (extension wins over core skill-researcher-hard)
ROUTE_OP="research" ROUTE_TYPE="cslib" ROUTE_DEFAULT="skill-researcher" ROUTE_EFFORT="hard"
run_test "hard: research/cslib extension override -> skill-cslib-research-hard" "skill-cslib-research-hard"

# (implement, cslib, hard) -> skill-cslib-implementation-hard (extension wins over core skill-implementer-hard)
ROUTE_OP="implement" ROUTE_TYPE="cslib" ROUTE_DEFAULT="skill-implementer" ROUTE_EFFORT="hard"
run_test "hard: implement/cslib extension override -> skill-cslib-implementation-hard" "skill-cslib-implementation-hard"

echo ""

# --- Hard-mode: no hard variant (Step 4e safety gate) ---
echo "=== Hard-mode: no hard variant fallback (Step 4e safety gate) ==="

# neovim has no routing_hard entry in any manifest AND no skill-neovim-research-hard/SKILL.md
# Expected: fall back to standard skill, emit stderr note
ROUTE_OP="research" ROUTE_TYPE="neovim" ROUTE_DEFAULT="skill-researcher" ROUTE_EFFORT="hard"
# neovim research normally routes to skill-neovim-research (from extension)
# But skill-neovim-research-hard/SKILL.md does not exist, so fallback to standard
# The "standard" here is skill-neovim-research (from standard extension routing, Step 1-3)
run_test "hard: no-hard-variant emits stderr note + keeps standard skill" "skill-neovim-research" "[route] No hard variant for skill-neovim-research; using standard skill"

# Also test with a type that has no extension routing (stays at default)
# nix has no hard skills deployed; defaults to skill-nix-implementation from extension routing
ROUTE_OP="implement" ROUTE_TYPE="nix" ROUTE_DEFAULT="skill-implementer" ROUTE_EFFORT="hard"
run_test "hard: nix no-hard-variant -> skill-nix-implementation + stderr note" "skill-nix-implementation" "[route] No hard variant for skill-nix-implementation; using standard skill"

echo ""

# --- Hard-mode: compound key fallback ---
echo "=== Hard-mode: compound key base-type fallback ==="

# cslib:pr has no explicit routing_hard entry; base type "cslib" is in cslib extension routing_hard.implement
# (The cslib extension declares routing_hard.implement.cslib but NOT routing_hard.implement.pr)
# So compound key "cslib:pr" should fall back to base "cslib" -> skill-cslib-implementation-hard
ROUTE_OP="implement" ROUTE_TYPE="cslib:pr" ROUTE_DEFAULT="skill-implementer" ROUTE_EFFORT="hard"
run_test "hard: compound key cslib:pr falls back to base cslib -> skill-cslib-implementation-hard" "skill-cslib-implementation-hard"

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failures:"
  printf "%b\n" "$FAILURES"
  exit 1
fi

echo ""
echo "All tests passed."
exit 0
