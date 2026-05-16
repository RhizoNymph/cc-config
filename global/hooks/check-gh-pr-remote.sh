#!/bin/bash

if ! command -v jq &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

if ! echo "$COMMAND" | grep -qE '\bgh\s+pr\s+create\b'; then
  exit 0
fi

normalize_repo() {
  local v="$1"
  v="${v#\"}"; v="${v%\"}"
  v="${v#\'}"; v="${v%\'}"
  v="${v%.git}"
  v="${v%/}"
  local repo="${v##*/}"
  local rest="${v%/"$repo"}"
  local owner="${rest##*[/:]}"
  printf '%s/%s' "$owner" "$repo" | tr '[:upper:]' '[:lower:]'
}

deny() {
  cat <<DENY
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$1"
  }
}
DENY
  exit 0
}

if echo "$COMMAND" | grep -qE '(^|\s)(--repo(=|\s)|-R(=|\s))'; then
  FLAG_COUNT=$(echo "$COMMAND" | grep -oE '(^|[[:space:]])(--repo|-R)([= ]|$)' | wc -l)
  if [ "$FLAG_COUNT" -gt 1 ]; then
    deny "Blocked: \`gh pr create\` was passed --repo/-R more than once. Use a single flag whose value matches origin, or omit it."
  fi

  REPO_ARG=""
  if [[ "$COMMAND" =~ (^|[[:space:]])--repo=([^[:space:]]+) ]]; then
    REPO_ARG="${BASH_REMATCH[2]}"
  elif [[ "$COMMAND" =~ (^|[[:space:]])-R=([^[:space:]]+) ]]; then
    REPO_ARG="${BASH_REMATCH[2]}"
  elif [[ "$COMMAND" =~ (^|[[:space:]])--repo[[:space:]]+([^[:space:]]+) ]]; then
    REPO_ARG="${BASH_REMATCH[2]}"
  elif [[ "$COMMAND" =~ (^|[[:space:]])-R[[:space:]]+([^[:space:]]+) ]]; then
    REPO_ARG="${BASH_REMATCH[2]}"
  fi

  if [ -z "$REPO_ARG" ]; then
    deny "Blocked: \`gh pr create\` uses --repo/-R but the value could not be parsed. Omit the flag to target origin."
  fi

  ORIGIN_URL=$(git config --local --get remote.origin.url 2>/dev/null)
  if [ -z "$ORIGIN_URL" ]; then
    deny "Blocked: \`gh pr create\` uses --repo/-R but origin has no URL configured, so the target can't be verified. Omit the flag or set origin."
  fi

  NORM_ARG=$(normalize_repo "$REPO_ARG")
  NORM_ORIGIN=$(normalize_repo "$ORIGIN_URL")

  if [ "$NORM_ARG" != "$NORM_ORIGIN" ]; then
    deny "Blocked: \`gh pr create --repo $REPO_ARG\` targets '$NORM_ARG', but origin is '$NORM_ORIGIN'. PRs must target origin — omit the flag or correct the value."
  fi
fi

# `GH_REPO=owner/repo` (as a prefix, via `env`, or after `export`) overrides the
# target the same way --repo does. Block any appearance in the command string.
if echo "$COMMAND" | grep -qE '(^|[[:space:];&|])GH_REPO='; then
  deny "Blocked: \`gh pr create\` may not be invoked with GH_REPO set. That env var retargets gh at a different repo. Remove it to use origin."
fi

# `gh repo set-default <remote>` records the choice as
# `remote.<name>.gh-resolved = base` in the repo's git config. Without --repo/-R,
# `gh pr create` follows that pointer — so we block if anything other than origin
# is the resolved base.
RESOLVED=$(git config --local --get-regexp '^remote\..*\.gh-resolved$' 2>/dev/null \
  | awk '$2 == "base" { sub(/^remote\./, "", $1); sub(/\.gh-resolved$/, "", $1); print $1 }')

for remote in $RESOLVED; do
  if [ "$remote" != "origin" ]; then
    deny "Blocked: \`gh repo set-default\` points \`gh pr create\` at remote '$remote', not origin. Run \`gh repo set-default origin\` to retarget, then retry."
  fi
done

exit 0
