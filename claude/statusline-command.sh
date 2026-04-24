#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd' | sed "s|^$HOME|~|")

# Helper: render a progress bar for a given percentage (0-100) with bar_width blocks
# Usage: make_bar <percentage> <bar_width>
make_bar() {
  pct=$1
  width=$2
  filled=$(printf '%.0f' "$(echo "$pct $width" | awk '{printf "%f", $1 * $2 / 100}')")
  empty=$((width - filled))
  bar=""
  i=0
  while [ $i -lt $filled ]; do
    bar="${bar}█"
    i=$((i + 1))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}░"
    i=$((i + 1))
  done
  printf "%s" "$bar"
}

# Helper: format remaining time until a Unix epoch as "残XdYh" / "残XhYm" / "残Ym"
format_remaining() {
  target_epoch="$1"
  [ -z "$target_epoch" ] && return
  now_epoch=$(date +%s)
  diff=$((target_epoch - now_epoch))
  if [ "$diff" -le 0 ]; then
    printf "残0m"
    return
  fi
  days=$((diff / 86400))
  hours=$(((diff % 86400) / 3600))
  minutes=$(((diff % 3600) / 60))
  if [ "$days" -gt 0 ]; then
    printf "残%dd%dh" "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf "残%dh%dm" "$hours" "$minutes"
  else
    printf "残%dm" "$minutes"
  fi
}

# Git branch + dirty state (__git_ps1 風)
git_branch=""
git_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -n "$git_dir" ]; then
  git_branch_raw=$(git -C "$git_dir" symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$git_branch_raw" ]; then
    state=""
    # staged changes (+)
    git -C "$git_dir" diff --cached --quiet 2>/dev/null || state="${state}+"
    # unstaged changes (*)
    git -C "$git_dir" diff --quiet 2>/dev/null || state="${state}*"
    # untracked files (%)
    if [ -n "$(git -C "$git_dir" ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
      state="${state}%"
    fi
    # stash ($)
    if git -C "$git_dir" rev-parse --verify refs/stash >/dev/null 2>&1; then
      state="${state}\$"
    fi
    # upstream divergence
    upstream=""
    ahead=$(git -C "$git_dir" rev-list --count @{u}..HEAD 2>/dev/null)
    behind=$(git -C "$git_dir" rev-list --count HEAD..@{u} 2>/dev/null)
    if [ -n "$ahead" ] && [ -n "$behind" ]; then
      if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        upstream="<>"
      elif [ "$ahead" -gt 0 ]; then
        upstream=">"
      elif [ "$behind" -gt 0 ]; then
        upstream="<"
      fi
    fi
    git_branch=" (${git_branch_raw}${state}${upstream})"
  fi
fi

# Model info
model=$(echo "$input" | jq -r '.model.display_name // empty' | sed 's/^Claude //')
model_str=""
if [ -n "$model" ]; then
  model_str="$model"
fi

# Rate limit progress bars (5h and 7d)
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
rate_str=""
if [ -n "$five" ]; then
  five_int=$(printf '%.0f' "$five")
  five_bar=$(make_bar "$five" 10)
  rate_str="${rate_str}5h:[${five_bar}]${five_int}%"
  five_left=$(format_remaining "$five_reset")
  if [ -n "$five_left" ]; then
    rate_str="${rate_str} ${five_left}"
  fi
fi
if [ -n "$five" ] && [ -n "$week" ]; then
  rate_str="${rate_str} "
fi
if [ -n "$week" ]; then
  week_int=$(printf '%.0f' "$week")
  week_bar=$(make_bar "$week" 10)
  rate_str="${rate_str}7d:[${week_bar}]${week_int}%"
  week_left=$(format_remaining "$week_reset")
  if [ -n "$week_left" ]; then
    rate_str="${rate_str} ${week_left}"
  fi
fi

# Context window progress bar
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_str=""
if [ -n "$ctx_used" ]; then
  ctx_int=$(printf '%.0f' "$ctx_used")
  ctx_bar=$(make_bar "$ctx_used" 10)
  # Color: green(<50%), yellow(50-79%), red(>=80%)
  if [ "$ctx_int" -ge 80 ]; then
    ctx_color="\033[31m"
  elif [ "$ctx_int" -ge 50 ]; then
    ctx_color="\033[33m"
  else
    ctx_color="\033[32m"
  fi
  ctx_str=$(printf "${ctx_color}ctx:[%s]%d%%\033[0m" "$ctx_bar" "$ctx_int")
fi

# Line 1: host + path + git branch
line1=$(printf "\033[32m%s@%s\033[0m \033[36m%s\033[0m\033[31m%s\033[0m" \
  "$(whoami)" "$(hostname -s)" "$cwd" "$git_branch")

# Line 2: rate limits | context | model
line2_parts=""
if [ -n "$rate_str" ]; then
  line2_parts=$(printf "\033[33m%s\033[0m" "$rate_str")
fi
sep=$(printf "\033[0m | ")
if [ -n "$ctx_str" ]; then
  if [ -n "$line2_parts" ]; then
    line2_parts="${line2_parts}${sep}${ctx_str}"
  else
    line2_parts="${ctx_str}"
  fi
fi
if [ -n "$model_str" ]; then
  if [ -n "$line2_parts" ]; then
    line2_parts="${line2_parts}${sep}$(printf "\033[35m%s\033[0m" "$model_str")"
  else
    line2_parts=$(printf "\033[35m%s\033[0m" "$model_str")
  fi
fi

if [ -n "$line2_parts" ]; then
  printf "%s\n%s" "$line1" "$line2_parts"
else
  printf "%s" "$line1"
fi
