#!/bin/bash
#
# PreToolUse hook: blocks `gh pr create` targeting a non-origin remote.
# `gh pr create` without --repo/-R uses the current repo's default (origin).
# The only way to retarget another repo is via --repo or -R, so block those.

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

if echo "$COMMAND" | grep -qE '(^|\s)(--repo(=|\s)|-R(=|\s))'; then
  cat <<DENY
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked: \`gh pr create\` may not use --repo / -R. PRs must target the origin remote — omit the flag to use the current repository's default."
  }
}
DENY
  exit 0
fi

# `GH_REPO=owner/repo` (as a prefix, via `env`, or after `export`) overrides the
# target the same way --repo does. Block any appearance in the command string.
if echo "$COMMAND" | grep -qE '(^|[[:space:];&|])GH_REPO='; then
  cat <<DENY
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked: \`gh pr create\` may not be invoked with GH_REPO set. That env var retargets gh at a different repo. Remove it to use origin."
  }
}
DENY
  exit 0
fi

# `gh repo set-default <remote>` records the choice as
# `remote.<name>.gh-resolved = base` in the repo's git config. Without --repo/-R,
# `gh pr create` follows that pointer — so we block if anything other than origin
# is the resolved base.
RESOLVED=$(git config --local --get-regexp '^remote\..*\.gh-resolved$' 2>/dev/null \
  | awk '$2 == "base" { sub(/^remote\./, "", $1); sub(/\.gh-resolved$/, "", $1); print $1 }')

for remote in $RESOLVED; do
  if [ "$remote" != "origin" ]; then
    cat <<DENY
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked: \`gh repo set-default\` points \`gh pr create\` at remote '$remote', not origin. Run \`gh repo set-default origin\` to retarget, then retry."
  }
}
DENY
    exit 0
  fi
done

exit 0
