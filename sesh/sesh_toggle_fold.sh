#!/usr/bin/env bash
# Toggle fold state for a parent session.
# Called by fzf with {1} (the ORIGINAL column from sesh_tree_list.sh).
#
# Extracts the bare session name, derives the parent prefix (before first "/"),
# and toggles that parent in $SESH_FOLD_FILE.

[ -z "$SESH_FOLD_FILE" ] && exit 0
[ -z "$1" ] && exit 0

# Strip ANSI escape sequences
clean=$(printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g')

# Skip sesh type field (first space-delimited word), then skip session icon (second word)
# to get the bare name
bare=$(printf '%s' "$clean" | awk '{
  # Skip first field (sesh type icon)
  rest = substr($0, index($0, " ") + 1)
  # Skip second field (session icon)
  if (match(rest, / /)) {
    print substr(rest, RSTART + 1)
  } else {
    print rest
  }
}')

# Derive parent: if bare name contains "/", take prefix before first "/"
slash_pos=$(printf '%s' "$bare" | awk '{ print index($0, "/") }')
if [ "$slash_pos" -gt 0 ] 2>/dev/null; then
  parent="${bare%%/*}"
else
  parent="$bare"
fi

[ -z "$parent" ] && exit 0

# Ensure fold file directory exists
mkdir -p "$(dirname "$SESH_FOLD_FILE")"

# Toggle: remove if present, add if absent
if [ -f "$SESH_FOLD_FILE" ] && grep -qxF "$parent" "$SESH_FOLD_FILE"; then
  grep -vxF "$parent" "$SESH_FOLD_FILE" > "$SESH_FOLD_FILE.tmp"
  mv "$SESH_FOLD_FILE.tmp" "$SESH_FOLD_FILE"
else
  printf '%s\n' "$parent" >> "$SESH_FOLD_FILE"
fi
