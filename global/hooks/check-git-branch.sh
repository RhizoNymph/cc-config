#!/bin/bash
#
# PreToolUse hook: prevents pushing to protected branches.
# Parses the git push command to determine the actual target branch
# rather than relying on wildcard deny rules.

if ! command -v jq &>/dev/null; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Hook error: jq not installed. Cannot verify branch safety."}}'
  exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check commands that start with git push
if ! echo "$COMMAND" | grep -qE '^\s*git\s+push\b'; then
  exit 0
fi

PROTECTED_BRANCHES=("main" "master" "production")

# Strip 'git push' prefix and trailing whitespace
ARGS=$(echo "$COMMAND" | sed -E 's/^\s*git\s+push\s*//' | sed -E 's/\s*$//')

# Separate flags from positional arguments
POSITIONAL=()
SKIP_NEXT=false
for word in $ARGS; do
  if $SKIP_NEXT; then
    SKIP_NEXT=false
    continue
  fi
  case "$word" in
    # Flags that take no value
    -u|--set-upstream|-f|--force|--no-verify|--dry-run|-n|--thin|--no-thin)
      continue ;;
    --quiet|-q|--verbose|-v|--progress|--all|--mirror|--tags|--delete|-d)
      continue ;;
    --prune|--atomic|--force-if-includes|--no-force-with-lease)
      continue ;;
    # --force-with-lease can be --force-with-lease or --force-with-lease=ref
    --force-with-lease|--force-with-lease=*)
      continue ;;
    # Flags that consume the next word as a value
    --repo|--receive-pack|--exec|-o|--push-option|--signed)
      SKIP_NEXT=true
      continue ;;
    # Skip any other flags
    -*)
      continue ;;
    # Positional argument
    *)
      POSITIONAL+=("$word") ;;
  esac
done

# Positional layout: [remote] [refspec ...]
# If 0 or 1 positional args, no refspec was given — target is current branch.
# If 2+, everything after the first is a refspec.
TARGET_BRANCHES=()
if [ ${#POSITIONAL[@]} -le 1 ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    TARGET_BRANCHES+=("$BRANCH")
  fi
else
  for ((i = 1; i < ${#POSITIONAL[@]}; i++)); do
    REFSPEC="${POSITIONAL[$i]}"
    if echo "$REFSPEC" | grep -q ':'; then
      # local:remote — the remote side is the target
      TARGET_BRANCHES+=("${REFSPEC##*:}")
    else
      TARGET_BRANCHES+=("$REFSPEC")
    fi
  done
fi

# Check each target branch against the protected list
for target in "${TARGET_BRANCHES[@]}"; do
  for protected in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$target" == "$protected" ]]; then
      cat <<DENY
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Cannot push to protected branch: $target. Use a feature branch and open a PR instead."
  }
}
DENY
      exit 0
    fi
  done
done

exit 0
