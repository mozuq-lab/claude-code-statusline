#!/bin/bash
# Claude Code status line:
# [Model · effort] 📁 dir ⎇ branch | ctx NN% | session NN% (Xh Ym) | week NN% (Xd Yh)
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$cwd")

branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

now=$(date +%s)

# Format an epoch reset time as remaining "Xd Yh" / "Xh Ym" / "Xm" (empty if past/invalid)
fmt_remaining() {
  local target=${1%.*}
  [ -z "$target" ] && return
  local secs=$(( target - now ))
  [ "$secs" -le 0 ] && return
  local d=$(( secs / 86400 ))
  local h=$(( (secs % 86400) / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh %dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

model_seg="$model"
[ -n "$effort" ] && model_seg="$model · $effort"
out="[$model_seg] 📁 $dir_name"
[ -n "$branch" ] && out="$out ⎇ $branch"

if [ -n "$used" ]; then
  out="$out | ctx $(printf '%.0f' "$used")%"
fi
if [ -n "$session_used" ]; then
  seg="session $(printf '%.0f' "$session_used")%"
  rem=$(fmt_remaining "$session_reset")
  [ -n "$rem" ] && seg="$seg ($rem)"
  out="$out | $seg"
fi
if [ -n "$week_used" ]; then
  seg="week $(printf '%.0f' "$week_used")%"
  rem=$(fmt_remaining "$week_reset")
  [ -n "$rem" ] && seg="$seg ($rem)"
  out="$out | $seg"
fi

printf '%s' "$out"
