#!/usr/bin/env bash
# Shared setup for all bats test files.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIR="$REPO_ROOT"

# Load bats helpers
load "${REPO_ROOT}/tests/libs/bats-support/load.bash"
load "${REPO_ROOT}/tests/libs/bats-assert/load.bash"
load "${REPO_ROOT}/tests/libs/bats-file/load.bash"
