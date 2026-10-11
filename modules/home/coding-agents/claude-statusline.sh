#!/usr/bin/env bash
# Claude Code status line: model | repo:branch* or path | context | cost | +/- lines
input=$(cat)

j() { jq -r "$1 // empty" <<<"$input"; }

model=$(j '.model.display_name')
cwd=$(j '.workspace.current_dir')
[ -z "$cwd" ] && cwd=$(j '.cwd')
cost=$(j '.cost.total_cost_usd')
added=$(j '.cost.total_lines_added')
removed=$(j '.cost.total_lines_removed')
ctx=$(j '.context_window.used_percentage')
style=$(j '.output_style.name')

# Colours
R=$'\e[0m'; DIM=$'\e[2m'; CYAN=$'\e[36m'; MAG=$'\e[35m'; GRN=$'\e[32m'
RED=$'\e[31m'; YEL=$'\e[33m'; BLU=$'\e[34m'
SEP="${DIM} │ ${R}"

# Location: repo name + branch when inside git, else ~-shortened path
loc=""
if top=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null); then
  repo=$(basename "$top")
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  dirty=""
  [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain -uno 2>/dev/null | head -1)" ] && dirty="${YEL}*"
  sub=${cwd#"$top"}
  loc="${BLU}${repo}${DIM}${sub}${R} ${MAG}${branch}${dirty}${R}"
else
  loc="${BLU}${cwd/#$HOME/\~}${R}"
fi

out="${CYAN}${model:-?}${R}"
[ -n "$style" ] && [ "$style" != "default" ] && out+="${DIM} (${style})${R}"
out+="${SEP}${loc}"

if [ -n "$ctx" ]; then
  pct=${ctx%.*}
  c=$GRN; [ "$pct" -ge 50 ] && c=$YEL; [ "$pct" -ge 80 ] && c=$RED
  out+="${SEP}${c}ctx ${pct}%${R}"
fi

[ -n "$cost" ] && out+="${SEP}${DIM}\$$(printf '%.2f' "$cost")${R}"

if [ -n "$added$removed" ] && [ "${added:-0}${removed:-0}" != "00" ]; then
  out+="${SEP}${GRN}+${added:-0}${R} ${RED}-${removed:-0}${R}"
fi

printf '%s' "$out"
