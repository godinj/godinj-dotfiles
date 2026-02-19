#!/bin/bash
# Listens on port 2224 and pipes each connection to wl-copy.
# Runs as a systemd user service so the tunnel always has a target.
while true; do
  nc -l 127.0.0.1 2224 | wl-copy
done
