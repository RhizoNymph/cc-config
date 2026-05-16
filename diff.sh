#!/bin/bash
# Show diffs between global/ in this repo and what's installed at ~/.claude/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/global"
TARGET_DIR="$HOME/.claude"

SHOW_DIFF=true
REVERSE=false
USE_COLOR=auto
for arg in "$@"; do
  case "$arg" in
    -q|--quiet|--names-only) SHOW_DIFF=false ;;
    -r|--reverse) REVERSE=true ;;
    --color) USE_COLOR=always ;;
    --no-color) USE_COLOR=never ;;
    -h|--help)
      cat <<EOF
Usage: diff.sh [-q|--quiet] [-r|--reverse] [--color|--no-color]

Compares repo's global/ against installed ~/.claude/.
Prints full unified diffs for differing files by default.

  -q, --quiet     Only list names of differing files; skip diff bodies.
  -r, --reverse   Show installed -> repo (default: repo -> installed).
  --color         Force color output.
  --no-color      Disable color output.
EOF
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

# Color setup
if [ "$USE_COLOR" = always ] || { [ "$USE_COLOR" = auto ] && [ -t 1 ]; }; then
  C_RESET=$'\e[0m'
  C_BOLD=$'\e[1m'
  C_DIM=$'\e[2m'
  C_RED=$'\e[31m'
  C_GREEN=$'\e[32m'
  C_YELLOW=$'\e[33m'
  C_BLUE=$'\e[34m'
  C_MAGENTA=$'\e[35m'
  C_CYAN=$'\e[36m'
  GIT_COLOR=--color=always
else
  C_RESET= C_BOLD= C_DIM= C_RED= C_GREEN= C_YELLOW= C_BLUE= C_MAGENTA= C_CYAN=
  GIT_COLOR=--no-color
fi

REPO_LABEL="repo (global/)"
LIVE_LABEL="installed (~/.claude/)"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: $SOURCE_DIR not found" >&2
  exit 1
fi
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR not found" >&2
  exit 1
fi

differ=0
only_source=0
only_target=0
same=0

differs_list=()
only_source_list=()
only_target_list=()

print_diff_header() {
  local rel="$1" left_label="$2" right_label="$3"
  local stats
  stats=$( { diff "$SOURCE_DIR/$rel" "$TARGET_DIR/$rel" 2>/dev/null || true; } \
    | awk 'BEGIN{a=0;d=0} /^>/{a++} /^</{d++} END{printf "+%d -%d", a, d}')
  echo
  echo "${C_BOLD}${C_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo "${C_BOLD}${C_MAGENTA}  ${rel}${C_RESET}  ${C_DIM}(${stats})${C_RESET}"
  echo "${C_DIM}    ${left_label}  →  ${right_label}${C_RESET}"
  echo "${C_BOLD}${C_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
}

show_diff() {
  local rel="$1"
  local left="$SOURCE_DIR/$rel" right="$TARGET_DIR/$rel"
  local left_label="$REPO_LABEL" right_label="$LIVE_LABEL"
  if $REVERSE; then
    left="$TARGET_DIR/$rel"; right="$SOURCE_DIR/$rel"
    left_label="$LIVE_LABEL"; right_label="$REPO_LABEL"
  fi
  print_diff_header "$rel" "$left_label" "$right_label"
  # git diff --no-index gives nicer colored output than plain diff -u.
  # It exits 1 when files differ; capture so pipefail doesn't abort the script.
  local out
  out=$(git --no-pager diff $GIT_COLOR --no-index --no-prefix -- "$left" "$right" || true)
  # Strip the first 4 lines (git's "diff --git" / "index" / "---" / "+++" header)
  # since we already printed a clearer header above.
  printf '%s\n' "$out" | tail -n +5
}

walk() {
  local rel
  while IFS= read -r -d '' src; do
    rel="${src#$SOURCE_DIR/}"
    local tgt="$TARGET_DIR/$rel"
    if [ ! -e "$tgt" ]; then
      only_source_list+=("$rel")
    elif ! diff -q "$src" "$tgt" &>/dev/null; then
      differs_list+=("$rel")
    else
      same=$((same + 1))
    fi
  done < <(find "$SOURCE_DIR" -type f -print0)

  # Only check "only in target" under top-level paths that the repo tracks,
  # so we ignore runtime state like projects/, todos/, debug/, history.jsonl, etc.
  local tracked=()
  for entry in "$SOURCE_DIR"/*; do
    tracked+=("$(basename "$entry")")
  done

  for top in "${tracked[@]}"; do
    local src_top="$SOURCE_DIR/$top"
    local tgt_top="$TARGET_DIR/$top"
    [ -d "$src_top" ] || continue
    [ -d "$tgt_top" ] || continue
    while IFS= read -r -d '' tgt; do
      rel="${tgt#$TARGET_DIR/}"
      local src="$SOURCE_DIR/$rel"
      if [ ! -e "$src" ]; then
        only_target_list+=("$rel")
      fi
    done < <(find "$tgt_top" -type f -print0)
  done
}

walk

differ=${#differs_list[@]}
only_source=${#only_source_list[@]}
only_target=${#only_target_list[@]}

# Overview list first, before any diff bodies, so it's easy to scan
echo "${C_BOLD}Comparing${C_RESET} ${C_CYAN}${REPO_LABEL}${C_RESET} ${C_DIM}vs${C_RESET} ${C_CYAN}${LIVE_LABEL}${C_RESET}"
echo
if [ $differ -gt 0 ]; then
  echo "${C_BOLD}${C_YELLOW}● differs (${differ})${C_RESET}"
  for f in "${differs_list[@]}"; do echo "    ${C_YELLOW}~${C_RESET} $f"; done
fi
if [ $only_source -gt 0 ]; then
  echo "${C_BOLD}${C_GREEN}● only in repo (${only_source}) — not yet installed${C_RESET}"
  for f in "${only_source_list[@]}"; do echo "    ${C_GREEN}+${C_RESET} $f"; done
fi
if [ $only_target -gt 0 ]; then
  echo "${C_BOLD}${C_RED}● only installed (${only_target}) — missing from repo${C_RESET}"
  for f in "${only_target_list[@]}"; do echo "    ${C_RED}-${C_RESET} $f"; done
fi
if [ $differ -eq 0 ] && [ $only_source -eq 0 ] && [ $only_target -eq 0 ]; then
  echo "${C_GREEN}✓ all in sync${C_RESET} ($same files)"
fi

if $SHOW_DIFF && [ $differ -gt 0 ]; then
  for rel in "${differs_list[@]}"; do
    show_diff "$rel"
  done
fi

echo
echo "${C_DIM}Summary:${C_RESET} ${C_GREEN}$same same${C_RESET}, ${C_YELLOW}$differ differ${C_RESET}, ${C_GREEN}$only_source only-in-repo${C_RESET}, ${C_RED}$only_target only-installed${C_RESET}"
if [ "$differ" -gt 0 ] || [ "$only_source" -gt 0 ]; then
  exit 1
fi
