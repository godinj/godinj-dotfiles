#!/bin/sh
# Transform sesh list output into tree-structured tab-delimited format.
# Groups worktree children under their parent session with tree-style
# indentation for use with fzf --delimiter --with-nth --accept-nth.
#
# Parent matching is icon-agnostic: a child "󰀜 project/name" groups under
# parent "󱁤 project" even though the leading icons differ.
#
# fzf displays bottom-to-top, so children are emitted BEFORE their parent
# and tree chars are reversed (└── for first child, ├── for the rest).
#
# Input:  sesh list output (with --icons, including ANSI codes) on stdin
# Output: ORIGINAL<TAB>DISPLAY per line

exec awk '
BEGIN {
  fold_file = ENVIRON["SESH_FOLD_FILE"]
  has_fold_file = (fold_file != "")
  if (has_fold_file) {
    while ((getline fline < fold_file) > 0) {
      gsub(/^[ \t]+|[ \t]+$/, "", fline)
      if (fline != "") folded[fline] = 1
    }
    close(fold_file)
  }
}
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

  # Bare name = session name with leading session icon stripped (icon-agnostic matching)
  bn = session_name[total]
  if (match(bn, / /)) {
    bare[total] = substr(bn, RSTART + 1)
  } else {
    bare[total] = bn
  }
  bare_to_idx[bare[total]] = total
}

END {
  # Build parent-child relationships using bare names (icon-agnostic)
  for (i = 1; i <= total; i++) {
    bn = bare[i]
    slash = index(bn, "/")
    if (slash > 0) {
      parent_bare = substr(bn, 1, slash - 1)
      if (parent_bare in bare_to_idx) {
        pi = bare_to_idx[parent_bare]
        parent_full = session_name[pi]
        is_child[i] = parent_full
        if (children_of[parent_full] == "") {
          children_of[parent_full] = i
        } else {
          children_of[parent_full] = children_of[parent_full] " " i
        }
      }
    }
  }

  # Output lines with tree structure
  # Children are emitted BEFORE their parent (fzf shows bottom-to-top)
  for (i = 1; i <= total; i++) {
    if (emitted[i]) continue
    if (is_child[i] != "") continue  # Will be emitted before parent

    name = session_name[i]

    # Emit children before this parent
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

      parent_is_folded = (has_fold_file && (bare[i] in folded))

      if (parent_is_folded) {
        # Collapsed: skip children, emit parent with ▸ and child count
        for (j = 1; j <= pending_count; j++) {
          emitted[pending[j]] = 1
        }
        emitted[i] = 1
        printf "%s\t\xe2\x96\xb8 %s [%d]\n", lines[i], lines[i], pending_count
      } else {
        # Expanded: emit children with tree chars
        for (j = pending_count; j >= 1; j--) {
          ci = pending[j]
          emitted[ci] = 1

          # Extract session icon from child name (first word)
          child_name = session_name[ci]
          icon_end = index(child_name, " ")
          if (icon_end > 0) {
            icon = substr(child_name, 1, icon_end - 1)
          } else {
            icon = ""
          }

          # Extract child branch name from bare name (after the "/")
          child_slash = index(bare[ci], "/")
          branch = substr(bare[ci], child_slash + 1)

          if (j == 1) {
            tree = "\342\224\224\342\224\200\342\224\200 "
          } else {
            tree = "\342\224\234\342\224\200\342\224\200 "
          }

          printf "%s\t   %s%s %s\n", lines[ci], tree, icon, branch
        }

        emitted[i] = 1
        if (has_fold_file) {
          printf "%s\t\xe2\x96\xbe %s\n", lines[i], lines[i]
        } else {
          printf "%s\t%s\n", lines[i], lines[i]
        }
      }
    } else {
      emitted[i] = 1
      printf "%s\t%s\n", lines[i], lines[i]
    }
  }
}
'
