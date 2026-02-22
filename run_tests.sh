#!/usr/bin/env bash
# Convenience runner for bats unit tests.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BATS="$SCRIPT_DIR/tests/libs/bats-core/bin/bats"

# Find .bats files only in our test dirs (skip tests/libs/ which contains bats' own tests)
find "$SCRIPT_DIR/tests" -path "$SCRIPT_DIR/tests/libs" -prune -o -name '*.bats' -print \
  | sort \
  | xargs "$BATS" "$@"
