#!/usr/bin/env bash
# Claude Code status line script

input=$(cat)

# ANSI colors
RST="\033[0m"
WHITE="\033[1;37m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
DIM="\033[2m"

# Git branch
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

# Context window used %
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_int=$(printf '%.0f' "$ctx_used" 2>/dev/null)

# Color context by threshold
ctx_color=""
if [ -n "$ctx_int" ]; then
  if [ "$ctx_int" -ge 50 ]; then
    ctx_color="$RED"
  elif [ "$ctx_int" -ge 25 ]; then
    ctx_color="$YELLOW"
  fi
fi

# Cache hit % = cache_read / (cache_read + input_tokens)
cache_pct=""
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')
if [ -n "$cache_read" ] && [ "$cache_read" -gt 0 ] 2>/dev/null; then
  total_input=$(( input_tokens + cache_read ))
  if [ "$total_input" -gt 0 ]; then
    cache_pct=$(awk "BEGIN { printf \"%.0f\", ($cache_read / $total_input) * 100 }")
  fi
fi

# Session cost
session_cost=$(echo "$input" | jq -r '.session.cost // empty')
cost_str=""
if [ -n "$session_cost" ] && [ "$session_cost" != "null" ]; then
  cost_str=$(awk "BEGIN { printf \"$%.2f\", $session_cost }")
fi

# Session window: time elapsed % and usage %
five_h_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
five_h_time_pct=""
if [ -n "$five_h_resets" ] && [ "$five_h_resets" -gt 0 ] 2>/dev/null; then
  now=$(date +%s)
  window=18000
  elapsed=$(( window - (five_h_resets - now) ))
  if [ "$elapsed" -lt 0 ]; then elapsed=0; fi
  if [ "$elapsed" -gt "$window" ]; then elapsed=$window; fi
  five_h_time_pct=$(awk "BEGIN { printf \"%.0f\", ($elapsed / $window) * 100 }")
fi

# Weekly window: time elapsed % and usage %
week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
week_time_pct=""
if [ -n "$week_resets" ] && [ "$week_resets" -gt 0 ] 2>/dev/null; then
  now=$(date +%s)
  window=604800
  elapsed=$(( window - (week_resets - now) ))
  if [ "$elapsed" -lt 0 ]; then elapsed=0; fi
  if [ "$elapsed" -gt "$window" ]; then elapsed=$window; fi
  week_time_pct=$(awk "BEGIN { printf \"%.0f\", ($elapsed / $window) * 100 }")
fi

# Build output with clear separators
sep="${DIM} │ ${RST}"

result=""

# Branch (white bold)
if [ -n "$branch" ]; then
  result+="${WHITE}${branch}${RST}"
fi

# Context % (colored by threshold)
if [ -n "$ctx_used" ]; then
  result+="${sep}${ctx_color}ctx ${ctx_int}%${RST}"
fi

# Cache %
if [ -n "$cache_pct" ]; then
  result+="${sep}cached ${cache_pct}%"
fi

# Session cost
if [ -n "$cost_str" ]; then
  result+="${sep}cost ${cost_str}"
fi

# 5h session window
if [ -n "$five_h_time_pct" ] && [ -n "$five_h_used" ]; then
  five_h_ratio=""
  five_h_ratio_color=""
  if [ "$five_h_time_pct" -gt 0 ] 2>/dev/null; then
    five_h_ratio=$(awk "BEGIN { printf \"%.2f\", $five_h_used / $five_h_time_pct }")
    five_h_ratio_num=$(awk "BEGIN { print $five_h_used / $five_h_time_pct }")
    if awk "BEGIN { exit !($five_h_ratio_num >= 1.3) }"; then
      five_h_ratio_color="$RED"
    elif awk "BEGIN { exit !($five_h_ratio_num < 0.9 || $five_h_ratio_num > 1.1) }"; then
      five_h_ratio_color="$YELLOW"
    fi
  fi
  result+="${sep}5h ${five_h_time_pct}%t $(printf '%.0f' "$five_h_used")%u"
  if [ -n "$five_h_ratio" ]; then
    result+=" ${five_h_ratio_color}${five_h_ratio}${RST}"
  fi
elif [ -n "$five_h_used" ]; then
  result+="${sep}5h $(printf '%.0f' "$five_h_used")%u"
fi

# 7d weekly window
if [ -n "$week_time_pct" ] && [ -n "$week_used" ]; then
  week_ratio=""
  week_ratio_color=""
  if [ "$week_time_pct" -gt 0 ] 2>/dev/null; then
    week_ratio=$(awk "BEGIN { printf \"%.2f\", $week_used / $week_time_pct }")
    week_ratio_num=$(awk "BEGIN { print $week_used / $week_time_pct }")
    if awk "BEGIN { exit !($week_ratio_num >= 1.3) }"; then
      week_ratio_color="$RED"
    elif awk "BEGIN { exit !($week_ratio_num < 0.9 || $week_ratio_num > 1.1) }"; then
      week_ratio_color="$YELLOW"
    fi
  fi
  result+="${sep}7d ${week_time_pct}%t $(printf '%.0f' "$week_used")%u"
  if [ -n "$week_ratio" ]; then
    result+=" ${week_ratio_color}${week_ratio}${RST}"
  fi
elif [ -n "$week_used" ]; then
  result+="${sep}7d $(printf '%.0f' "$week_used")%u"
fi

echo -e "$result"
