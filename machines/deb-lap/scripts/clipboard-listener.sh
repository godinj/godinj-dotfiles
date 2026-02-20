#!/bin/bash
# Listens on port 2224 and pipes each connection to wl-copy.
# Runs as a systemd user service so the tunnel always has a target.

# nc.traditional needs -s/-p flags; BSD/openbsd nc uses positional args
if readlink -f "$(command -v nc)" 2>/dev/null | grep -q traditional; then
  NC_LISTEN="nc -l -s 127.0.0.1 -p 2224"
else
  NC_LISTEN="nc -l 127.0.0.1 2224"
fi

while true; do
  $NC_LISTEN | wl-copy
done
