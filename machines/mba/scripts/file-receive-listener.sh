#!/bin/bash
# Listens on port 2225 and receives files.
# Protocol: first line = filename (basename), rest = file contents.
# Writes to $MACHINE_RECEIVE_DIR (defaults to ~/Downloads).
RECEIVE_DIR="${MACHINE_RECEIVE_DIR:-$HOME/Downloads}"
mkdir -p "$RECEIVE_DIR"

while true; do
  {
    # Read the filename from the first line
    IFS= read -r raw_name

    # Sanitize: strip path components and control characters
    base="$(basename "$raw_name" | tr -d '[:cntrl:]')"

    # Skip if filename is empty after sanitization
    if [ -z "$base" ]; then
      cat > /dev/null
      continue
    fi

    # Handle filename collisions with _1, _2, etc. suffixes
    dest="$RECEIVE_DIR/$base"
    if [ -e "$dest" ]; then
      name="${base%.*}"
      ext="${base##*.}"
      # If there's no extension (name == ext), treat as no extension
      if [ "$name" = "$ext" ]; then
        ext=""
      fi
      counter=1
      while true; do
        if [ -n "$ext" ]; then
          dest="$RECEIVE_DIR/${name}_${counter}.${ext}"
        else
          dest="$RECEIVE_DIR/${base}_${counter}"
        fi
        [ ! -e "$dest" ] && break
        counter=$((counter + 1))
      done
    fi

    # Write remaining data to the file
    cat > "$dest"
    echo "Received: $dest"
  } < <(nc -l 127.0.0.1 2225)
done
