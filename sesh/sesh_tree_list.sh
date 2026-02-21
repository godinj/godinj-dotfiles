#!/bin/sh
# Transform sesh list output into tree-structured tab-delimited format.
# Groups worktree children under their parent session with tree-style
# indentation for use with fzf --delimiter --with-nth --accept-nth.
#
# Input:  sesh list output (with --icons, including ANSI codes) on stdin
# Output: ORIGINAL<TAB>DISPLAY per line

exec awk '
{
  total++
  lines[total] = $0

  # Strip ANSI escape sequences to get plain text
  stripped = $0
  gsub(/\033\[[0-9;]*m/, "", stripped)

  # Session name = everything after the sesh type icon (first space-delimited field)
  if (match(stripped, / /)) {
    session_name[total] = substr(stripped, RSTART + 1)
  } else {
    session_name[total] = stripped
  }
  name_exists[session_name[total]] = 1
}

END {
  # Build parent-child relationships (only when parent exists in list)
  for (i = 1; i <= total; i++) {
    name = session_name[i]
    slash = index(name, "/")
    if (slash > 0) {
      parent = substr(name, 1, slash - 1)
      if (name_exists[parent]) {
        is_child[i] = parent
        if (children_of[parent] == "") {
          children_of[parent] = i
        } else {
          children_of[parent] = children_of[parent] " " i
        }
      }
    }
  }

  # Output lines with tree structure
  for (i = 1; i <= total; i++) {
    if (emitted[i]) continue
    if (is_child[i] != "") continue  # Will be emitted after parent

    emitted[i] = 1
    printf "%s\t%s\n", lines[i], lines[i]

    # Emit children of this parent
    name = session_name[i]
    if (children_of[name] != "") {
      n = split(children_of[name], child_arr, " ")

      # Count non-emitted children
      pending_count = 0
      for (j = 1; j <= n; j++) {
        ci = child_arr[j] + 0
        if (!emitted[ci]) {
          pending_count++
          pending[pending_count] = ci
        }
      }

      # Extract session icon from parent name (first word)
      icon_end = index(name, " ")
      if (icon_end > 0) {
        icon = substr(name, 1, icon_end - 1)
      } else {
        icon = ""
      }

      for (j = 1; j <= pending_count; j++) {
        ci = pending[j]
        emitted[ci] = 1
        branch = substr(session_name[ci], length(name) + 2)

        if (j == pending_count) {
          tree = "\342\224\224\342\224\200\342\224\200 "
        } else {
          tree = "\342\224\234\342\224\200\342\224\200 "
        }

        printf "%s\t   %s%s %s\n", lines[ci], tree, icon, branch
      }
    }
  }
}
'
