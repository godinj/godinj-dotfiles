export MACHINE_SSH_KEY=""
export MACHINE_DD_USER="jggodin"
export MACHINE_DD_HOST="dev-dsk-jggodin-2a-f83213c2.us-west-2.amazon.com"
export MACHINE_BD_HOST="dev-dsk-jggodin-2a-8ee4a126.us-west-2.amazon.com"
export MACHINE_DD_OPTS="-R 2224:127.0.0.1:2224"
export MACHINE_RECEIVE_DIR="${MACHINE_RECEIVE_DIR:-$HOME/Downloads}"

# SSH with reverse tunnels for clipboard and file transfer.
# Injects clip and send helper functions into the remote shell.
rsh() {
  if [ $# -lt 1 ]; then
    echo "Usage: rsh <host> [ssh-args...]" >&2
    return 1
  fi
  local host="$1"; shift
  ssh -t \
    -R 2224:127.0.0.1:2224 \
    -R 2225:127.0.0.1:2225 \
    "$@" "$host" \
    "exec bash --rcfile <(cat <<'REMOTE_RC'
clip() { cat | nc 127.0.0.1 2224; }
send() {
  if [ \$# -ne 1 ]; then
    echo \"Usage: send <file>\" >&2
    return 1
  fi
  local f=\"\$1\"
  if [ ! -f \"\$f\" ]; then
    echo \"send: not a file: \$f\" >&2
    return 1
  fi
  { printf '%s\n' \"\$(basename \"\$f\")\"; cat \"\$f\"; } | nc 127.0.0.1 2225
}
REMOTE_RC
)"
}
