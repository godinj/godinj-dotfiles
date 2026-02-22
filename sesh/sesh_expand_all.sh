#!/usr/bin/env bash
# Expand all folded parents by truncating the fold state file.

[ -z "$SESH_FOLD_FILE" ] && exit 0
: > "$SESH_FOLD_FILE"
