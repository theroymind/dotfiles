#!/usr/bin/env bash
# Claude Code status line -- Solarized Dark + Nerd Font powerline segments
#
# Line 1:  [path segment]  [branch segment]  trailing dots
# Line 2:  [model segment]  [ctx segment]  [5hr segment]  [reset segment]
# Line 3:  [7-day limit segment]  [reset segment]
#
# All Nerd Font glyphs use printf hex UTF-8 bytes -- safe on macOS bash 3.2
# which does not support \U escapes in $'...' for supplementary-plane codepoints.
#
# render_line writes into a named variable (printf -v) so it runs in the
# parent shell -- array clears at the end propagate back to the next line.
# It uses %s, not %b: bash 3.2 printf -v with an empty %b arg reuses the
# previous buffer, which would duplicate the prior line onto an empty one.

input=$(cat)

# ---------------------------------------------------------------------------
# ANSI helpers
# ---------------------------------------------------------------------------
RST=$'\033[0m'
BLD=$'\033[1m'
NBLD=$'\033[22m'   # bold off only -- does NOT reset colors, unlike RST
_fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
_bg() { printf '\033[48;2;%d;%d;%dm' "$1" "$2" "$3"; }
fg_of() { read -r _r _g _b <<< "$1"; _fg "$_r" "$_g" "$_b"; }
bg_of() { read -r _r _g _b <<< "$1"; _bg "$_r" "$_g" "$_b"; }

# ---------------------------------------------------------------------------
# Solarized Dark -- RGB triplets as "R G B" strings
# ---------------------------------------------------------------------------
rgb_base03="0 43 54"
rgb_base02="7 54 66"
rgb_base01="88 110 117"
rgb_base1="147 161 161"
rgb_base3="253 246 227"
rgb_yellow="181 137 0"
rgb_orange="203 75 22"
rgb_red="220 50 47"
rgb_blue="38 139 210"
rgb_cyan="42 161 152"
rgb_green="133 153 0"
rgb_gold="181 137 0"       # gold  -- branch with pending changes

# ---------------------------------------------------------------------------
# Nerd Font glyphs -- printf hex UTF-8 (no \U escape sequences)
# Codepoints in the PUA supplementary range (U+F0000-U+FFFFF) encode as
# 4-byte UTF-8: F0 8x xx xx
# ---------------------------------------------------------------------------

# U+E0B0  nf-pl-right-hard-divider  (powerline solid right arrow)
# UTF-8:  EE 82 B0
PL_RIGHT=$(printf '\xee\x82\xb0')

# U+F07C  nf-fa-folder_open
# UTF-8:  EF 81 BC
ICON_FOLDER=$(printf '\xef\x81\xbc')

# U+E0A0  nf-pl-branch
# UTF-8:  EE 82 A0
ICON_BRANCH=$(printf '\xee\x82\xa0')

# U+F069A  nf-md-robot
# UTF-8 4-byte encoding: F3 B0 9A 9A
# Verify: U=0xF069A=984730; b1=F0|(984730>>18)=F0|3=F3;
#   b2=80|((984730>>12)&3F)=80|30=B0; b3=80|((984730>>6)&3F)=80|1A=9A;
#   b4=80|(984730&3F)=80|1A=9A
ICON_AI=$(printf '\xf3\xb0\x9a\x9a')

# U+F05A5  nf-md-memory
# UTF-8: F3 B0 86 A5
# b1=F3, b2=B0, b3=80|(15366&3F)=80|06=86, b4=80|(983461&3F)=80|25=A5
ICON_CTX=$(printf '\xf3\xb0\x86\xa5')

# U+F0150  nf-md-clock
# UTF-8: F3 B0 9D 90
# b1=F3, b2=B0, b3=80|((984912>>6)&3F)=80|1D=9D, b4=80|(984912&3F)=80|10=90
ICON_CLOCK=$(printf '\xf3\xb0\x9d\x90')

# U+F021  nf-fa-refresh
# UTF-8:  EF 80 A1
ICON_RESET=$(printf '\xef\x80\xa1')

# ---------------------------------------------------------------------------
# Segment arrays (parallel)
# ---------------------------------------------------------------------------
_seg_text=()
_seg_bg=()
_seg_fg=()

push_seg() {
  # push_seg "rgb_bg" "rgb_fg" "text_content"
  _seg_bg+=("$1")
  _seg_fg+=("$2")
  _seg_text+=("$3")
}

# render_line VARNAME
# Builds the powerline string into VARNAME without a subshell, then clears the
# segment arrays so the next line starts fresh. Uses printf -v with %s, NOT %b:
# in bash 3.2, printf -v with an empty %b argument silently reuses the previous
# printf buffer, which would make a zero-segment line duplicate the prior line.
render_line() {
  local _dest="$1"
  local _out=""
  local _n=${#_seg_text[@]}
  local _i
  for (( _i=0; _i<_n; _i++ )); do
    local _tbg="${_seg_bg[$_i]}"
    local _tfg="${_seg_fg[$_i]}"
    local _txt="${_seg_text[$_i]}"
    local _b; _b=$(bg_of "$_tbg")
    local _f; _f=$(fg_of "$_tfg")
    if [ "$_i" -eq 0 ]; then
      _out+="${_b}${_f} ${_txt} "
    else
      local _pbg="${_seg_bg[$(( _i - 1 ))]}"
      local _afg; _afg=$(fg_of "$_pbg")
      local _abg; _abg=$(bg_of "$_tbg")
      _out+="${_afg}${_abg}${PL_RIGHT}${_f} ${_txt} "
    fi
  done
  if [ "$_n" -gt 0 ]; then
    local _lbg="${_seg_bg[$(( _n - 1 ))]}"
    local _cfg; _cfg=$(fg_of "$_lbg")
    _out+="${RST}${_cfg}${PL_RIGHT}${RST}"
  fi
  printf -v "$_dest" '%s' "$_out"
  _seg_text=()
  _seg_bg=()
  _seg_fg=()
}

# ---------------------------------------------------------------------------
# Parse JSON -- single jq call for all fields
# ---------------------------------------------------------------------------
IFS=$'\t' read -r cwd model effort_level used_pct five_used five_reset week_used week_reset < <(
  printf '%s' "$input" | jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.effort.level // ""),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // "")
  ] | @tsv'
)

# ---------------------------------------------------------------------------
# Git info -- single git invocation returning toplevel + branch
# ---------------------------------------------------------------------------
worktree_root=""
git_branch=""
git_dirty=""
if [ -n "$cwd" ]; then
  git_info=$(git -C "$cwd" -c gc.auto=0 \
    rev-parse --show-toplevel --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$git_info" ]; then
    worktree_root=$(printf '%s\n' "$git_info" | head -1)
    git_branch=$(printf '%s\n' "$git_info" | tail -1)
    if [ "$git_branch" = "HEAD" ]; then
      git_branch=$(git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
    fi
    # Pending changes = any staged/unstaged/untracked entry
    if [ -n "$(git -C "$cwd" -c gc.auto=0 status --porcelain 2>/dev/null)" ]; then
      git_dirty=1
    fi
  fi
fi

# ---------------------------------------------------------------------------
# LINE 1: path  branch
# ---------------------------------------------------------------------------
line1=""

if [ -n "$worktree_root" ]; then
  short_root="${worktree_root/#$HOME/~}"
  push_seg "$rgb_base02" "$rgb_base1"  "${ICON_FOLDER} ${BLD}${short_root}${NBLD}"
  if [ -n "$git_branch" ]; then
    if [ -n "$git_dirty" ]; then
      branch_bg="$rgb_gold";    branch_fg="$rgb_base03"   # gold, dark text
    else
      branch_bg="$rgb_base02";  branch_fg="$rgb_base1"    # match pwd segment
    fi
    push_seg "$branch_bg" "$branch_fg" "${ICON_BRANCH} ${git_branch}"
  fi
elif [ -n "$cwd" ]; then
  short_cwd="${cwd/#$HOME/~}"
  push_seg "$rgb_base02" "$rgb_base1"  "${ICON_FOLDER} ${BLD}${short_cwd}${NBLD}"
fi

render_line line1

# ---------------------------------------------------------------------------
# LINE 2: model  ctx  5hr  reset
# ---------------------------------------------------------------------------
line2=""

# Thinking effort -> 3-letter abbreviation (field absent when model lacks the param)
effort_abbr=""
case "$effort_level" in
  low)    effort_abbr="LOW" ;;
  medium) effort_abbr="MED" ;;
  high)   effort_abbr="HGH" ;;
  xhigh)  effort_abbr="XHI" ;;
  max)    effort_abbr="MAX" ;;
esac

if [ -n "$model" ]; then
  model_text="${ICON_AI} ${model}"
  [ -n "$effort_abbr" ] && model_text+=" ${effort_abbr}"
  push_seg "$rgb_blue" "$rgb_base03" "$model_text"
fi

if [ -n "$used_pct" ] && [ "$used_pct" != "null" ] && [ "$used_pct" != "" ]; then
  pct_int=$(printf "%.0f" "$used_pct")
  if   [ "$pct_int" -ge 90 ]; then ctx_bg="$rgb_red";    ctx_fg="$rgb_base3"
  elif [ "$pct_int" -ge 75 ]; then ctx_bg="$rgb_orange";  ctx_fg="$rgb_base3"
  elif [ "$pct_int" -ge 50 ]; then ctx_bg="$rgb_yellow";  ctx_fg="$rgb_base03"
  else                              ctx_bg="$rgb_base02";  ctx_fg="$rgb_cyan"
  fi
  bar=""
  filled=$(( pct_int * 8 / 100 ))
  for (( i=0;      i<filled; i++ )); do bar+="$(printf '\xe2\x96\x88')"; done
  for (( i=filled; i<8;      i++ )); do bar+="$(printf '\xe2\x96\x91')"; done
  push_seg "$ctx_bg" "$ctx_fg" "${ICON_CTX} ${bar} ${pct_int}%"
fi

if [ -n "$five_used" ] && [ "$five_used" != "null" ] && [ "$five_used" != "" ]; then
  five_int=$(printf "%.0f" "$five_used" 2>/dev/null)
  : "${five_int:=0}"
fi
if [ -n "$five_int" ] && [ "$five_int" -ge 0 ] && [ "$five_int" -le 100 ] 2>/dev/null; then
  five_rem=$(( 100 - five_int ))
  if   [ "$five_int" -ge 90 ]; then lim_bg="$rgb_red";    lim_fg="$rgb_base3"
  elif [ "$five_int" -ge 70 ]; then lim_bg="$rgb_orange";  lim_fg="$rgb_base3"
  elif [ "$five_int" -ge 40 ]; then lim_bg="$rgb_yellow";  lim_fg="$rgb_base03"
  else                               lim_bg="$rgb_base02";  lim_fg="$rgb_green"
  fi
  push_seg "$lim_bg" "$lim_fg" "${ICON_CLOCK} 5h ${five_rem}% left"
fi

if [ -n "$five_reset" ] && [ "$five_reset" != "null" ] && [ "$five_reset" != "" ]; then
  now=$(date +%s)
  delta=$(( five_reset - now ))
  if [ "$delta" -gt 0 ]; then
    mtot=$(( delta / 60 ))
    hrs=$(( mtot / 60 ))
    mins=$(( mtot % 60 ))
    if [ "$hrs" -gt 0 ]; then rst_str="${hrs}h${mins}m"
    else                       rst_str="${mins}m"
    fi
    push_seg "$rgb_base01" "$rgb_base1" "${ICON_RESET} ${rst_str}"
  fi
fi

render_line line2

# ---------------------------------------------------------------------------
# LINE 3: weekly (7-day) limit  reset
# ---------------------------------------------------------------------------
line3=""

if [ -n "$week_used" ] && [ "$week_used" != "null" ] && [ "$week_used" != "" ]; then
  week_int=$(printf "%.0f" "$week_used" 2>/dev/null)
  : "${week_int:=0}"
fi
if [ -n "$week_int" ] && [ "$week_int" -ge 0 ] && [ "$week_int" -le 100 ] 2>/dev/null; then
  week_rem=$(( 100 - week_int ))
  if   [ "$week_int" -ge 90 ]; then wk_bg="$rgb_red";    wk_fg="$rgb_base3"
  elif [ "$week_int" -ge 70 ]; then wk_bg="$rgb_orange";  wk_fg="$rgb_base3"
  elif [ "$week_int" -ge 40 ]; then wk_bg="$rgb_yellow";  wk_fg="$rgb_base03"
  else                               wk_bg="$rgb_base02";  wk_fg="$rgb_green"
  fi
  push_seg "$wk_bg" "$wk_fg" "${ICON_CLOCK} 7d ${week_rem}% left"
fi

if [ -n "$week_reset" ] && [ "$week_reset" != "null" ] && [ "$week_reset" != "" ]; then
  now=$(date +%s)
  delta=$(( week_reset - now ))
  if [ "$delta" -gt 0 ]; then
    days=$(( delta / 86400 ))
    hrs=$(( (delta % 86400) / 3600 ))
    mins=$(( (delta % 3600) / 60 ))
    if   [ "$days" -gt 0 ]; then rst_str="${days}d${hrs}h"
    elif [ "$hrs" -gt 0 ];  then rst_str="${hrs}h${mins}m"
    else                         rst_str="${mins}m"
    fi
    push_seg "$rgb_base01" "$rgb_base1" "${ICON_RESET} ${rst_str}"
  fi
fi

render_line line3

# ---------------------------------------------------------------------------
# Output -- join all non-empty lines with newlines
# ---------------------------------------------------------------------------
out=""
for ln in "$line1" "$line2" "$line3"; do
  if [ -n "$ln" ]; then
    if [ -n "$out" ]; then out+=$'\n'; fi
    out+="$ln"
  fi
done
printf '%b' "$out"
