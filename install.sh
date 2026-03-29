#!/bin/bash
# Install cc-config: syncs global/ contents to ~/.claude/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/global"
TARGET_DIR="$HOME/.claude"

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: $SOURCE_DIR not found"
  exit 1
fi

mkdir -p "$TARGET_DIR"

# Files that should not be blindly overwritten
MERGE_FILES=("CLAUDE.md" "settings.json" "settings.local.json")

for item in "$SOURCE_DIR"/*; do
  name="$(basename "$item")"
  target="$TARGET_DIR/$name"

  if [ -d "$item" ]; then
    mkdir -p "$target"
    cp -r "$item"/. "$target"/
    echo "  synced dir:  $name/"
  else
    skip=false
    if ! $FORCE; then
      for mf in "${MERGE_FILES[@]}"; do
        if [[ "$name" == "$mf" ]] && [ -f "$target" ]; then
          if ! diff -q "$item" "$target" &>/dev/null; then
            echo "  DIFFERS:     $name (use --force to overwrite, or merge manually)"
            echo "               diff $item $target"
            skip=true
          fi
          break
        fi
      done
    fi
    if ! $skip; then
      cp "$item" "$target"
      echo "  installed:   $name"
    fi
  fi
done

echo "Done."
