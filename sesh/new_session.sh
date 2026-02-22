#!/usr/bin/env bash
set -euo pipefail

# Interactive script to add a new project session to sesh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve machine profile
source "$DOTFILES_DIR/machine.sh"

PROJECTS_DIR="$MACHINE_DIR/sesh/sessions"
PROJECTS_FILE="$PROJECTS_DIR/projects.toml"

# Prompt for session details
read -rp "Session name: " name
[ -z "$name" ] && echo "Error: name cannot be empty" >&2 && exit 1

read -rp "Path [~/git/${name}/]: " path
path="${path:-~/git/${name}/}"

# Ensure trailing slash
[[ "$path" != */ ]] && path="${path}/"

read -rp "Startup command [nvim]: " startup_command
startup_command="${startup_command:-nvim}"

# Create the directory if it doesn't exist
expanded_path="${path/#\~/$HOME}"
if [ ! -d "$expanded_path" ]; then
  mkdir -p "$expanded_path"
  echo "Created directory: $path"
fi

# Ensure the sessions directory exists
mkdir -p "$PROJECTS_DIR"

# Append the new session entry (bare name; icon added at build time)
{
  # Add a blank line separator if the file already has content
  if [ -s "$PROJECTS_FILE" ]; then
    printf '\n'
  fi
  cat <<EOF
[[session]]
name = "${name}"
path = "${path}"
startup_command = "${startup_command}"
EOF
} >> "$PROJECTS_FILE"

echo "Added session to $PROJECTS_FILE"

# Rebuild sesh config
"$SCRIPT_DIR/build_sesh_config.sh"

echo ""
echo "Session created:"
echo "  name:    ${name}"
echo "  path:    ${path}"
echo "  command: ${startup_command}"
echo "sesh.toml rebuilt."
