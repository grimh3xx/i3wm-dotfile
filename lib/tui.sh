# shellcheck shell=bash disable=SC2034
# tui.sh — interactive cards in plain bash: checklist (space/enter) and radio list.
# keys: ↑↓ or j/k move · space toggle · a all/none · enter confirm · q quit

TUI_W=72

_tui_out() { printf '%s' "$*" >/dev/tty; }
_tui_cleanup() { _tui_out $'\e[?25h'; stty echo icanon 2>/dev/null </dev/tty || true; }

# width of a string ignoring ANSI escapes (good enough for our ASCII + box chars)
_tui_len() { local s; s=$(printf '%s' "$1" | sed $'s/\e\\[[0-9;]*m//g'); printf '%s' "${#s}"; }

_tui_line() {   # _tui_line "content" → │ content (padded) │
  local c=$1 n
  n=$(_tui_len "$c")
  _tui_out "  ${C_DIM}│${C_RST} $c$(printf '%*s' $((TUI_W - 3 - n)) '')${C_DIM}│${C_RST}"$'\e[K\n'
}

_tui_top() {
  local t=" $1 " n
  n=$(_tui_len "$t")
  _tui_out "  ${C_DIM}╭─${C_RST}${C_BLU}${C_BLD}$t${C_RST}${C_DIM}$(printf '─%.0s' $(seq 1 $((TUI_W - 3 - n))))╮${C_RST}"$'\e[K\n'
}

_tui_bottom() {
  _tui_out "  ${C_DIM}╰$(printf '─%.0s' $(seq 1 $((TUI_W - 2))))╯${C_RST}"$'\e[K\n'
}

_tui_key() {   # reads one key → up/down/space/enter/all/quit/other
  local k rest
  IFS= read -rsn1 k </dev/tty || { echo quit; return; }
  if [[ $k == $'\e' ]]; then
    IFS= read -rsn2 -t 0.05 rest </dev/tty || true
    case $rest in '[A') echo up ;; '[B') echo down ;; '') echo quit ;; *) echo other ;; esac
    return
  fi
  case $k in
    k|K) echo up ;; j|J) echo down ;; ' ') echo space ;; '') echo enter ;;
    a|A) echo all ;; q|Q) echo quit ;; *) echo other ;;
  esac
}

# tui_checklist TITLE SUBTITLE ITEM...
#   ITEM = "id|label|description|on(0/1)|locked(0/1)"
#   result: TUI_RESULT=(ids...)   returns 1 if the user quit
tui_checklist() {
  local title=$1 sub=$2; shift 2
  local -a ids=() labels=() descs=() on=() locked=()
  local it id label desc o l i cur=0 n key lines
  for it in "$@"; do
    IFS='|' read -r id label desc o l <<<"$it"
    ids+=("$id"); labels+=("$label"); descs+=("$desc"); on+=("$o"); locked+=("$l")
  done
  n=${#ids[@]}
  lines=$((n + 6))
  _tui_out $'\e[?25l'
  local first=1
  while :; do
    ((first)) || _tui_out $'\e['"$lines"'A'
    first=0
    _tui_top "$title"
    _tui_line "${C_DIM}$sub${C_RST}"
    _tui_line ""
    for ((i = 0; i < n; i++)); do
      local box ptr name
      if ((locked[i])); then box="${C_DIM}[■]${C_RST}"
      elif ((on[i])); then box="${C_CYN}[■]${C_RST}"
      else box="${C_DIM}[ ]${C_RST}"; fi
      if ((i == cur)); then ptr="${C_BLU}❯${C_RST}"; name="${C_BLD}$(printf '%-11s' "${labels[i]}")${C_RST}"
      else ptr=" "; name="$(printf '%-11s' "${labels[i]}")"; fi
      _tui_line "$ptr $box $name ${C_DIM}${descs[i]}${C_RST}"
    done
    _tui_line ""
    _tui_line "${C_DIM}↑↓ move · ${C_RST}space${C_DIM} toggle · ${C_RST}a${C_DIM} all · ${C_RST}enter${C_DIM} confirm · ${C_RST}q${C_DIM} quit${C_RST}"
    _tui_bottom
    key=$(_tui_key)
    case $key in
      up)    cur=$(((cur - 1 + n) % n)) ;;
      down)  cur=$(((cur + 1) % n)) ;;
      space) ((locked[cur])) || on[cur]=$((1 - on[cur])) ;;
      all)   local any=0; for ((i = 0; i < n; i++)); do ((locked[i] || on[i])) || any=1; done
             for ((i = 0; i < n; i++)); do ((locked[i])) || on[i]=$any; done ;;
      enter) break ;;
      quit)  _tui_cleanup; return 1 ;;
    esac
  done
  _tui_cleanup
  TUI_RESULT=()
  for ((i = 0; i < n; i++)); do ((on[i] || locked[i])) && TUI_RESULT+=("${ids[i]}"); done
  return 0
}

# tui_radio TITLE SUBTITLE ITEM...   ITEM = "id|label|description"   result: TUI_CHOICE=id
tui_radio() {
  local title=$1 sub=$2; shift 2
  local -a ids=() labels=() descs=()
  local it id label desc i cur=0 n key lines
  for it in "$@"; do
    IFS='|' read -r id label desc <<<"$it"
    ids+=("$id"); labels+=("$label"); descs+=("$desc")
  done
  n=${#ids[@]}
  lines=$((n + 6))
  _tui_out $'\e[?25l'
  local first=1
  while :; do
    ((first)) || _tui_out $'\e['"$lines"'A'
    first=0
    _tui_top "$title"
    _tui_line "${C_DIM}$sub${C_RST}"
    _tui_line ""
    for ((i = 0; i < n; i++)); do
      if ((i == cur)); then
        _tui_line "${C_BLU}❯${C_RST} ${C_CYN}(●)${C_RST} ${C_BLD}$(printf '%-9s' "${labels[i]}")${C_RST} ${C_DIM}${descs[i]}${C_RST}"
      else
        _tui_line "  ${C_DIM}( )${C_RST} $(printf '%-9s' "${labels[i]}") ${C_DIM}${descs[i]}${C_RST}"
      fi
    done
    _tui_line ""
    _tui_line "${C_DIM}↑↓ move · ${C_RST}enter${C_DIM} select · ${C_RST}q${C_DIM} quit${C_RST}"
    _tui_bottom
    key=$(_tui_key)
    case $key in
      up)    cur=$(((cur - 1 + n) % n)) ;;
      down)  cur=$(((cur + 1) % n)) ;;
      enter|space) break ;;
      quit)  _tui_cleanup; return 1 ;;
    esac
  done
  _tui_cleanup
  TUI_CHOICE=${ids[cur]}
}

# tui_summary TITLE LINE... — static card
tui_summary() {
  local title=$1 l; shift
  _tui_top "$title"
  for l in "$@"; do _tui_line "$l"; done
  _tui_bottom
}

# tui_confirm "question" — enter = yes, q/n = no
tui_confirm() {
  local k
  _tui_out "  ${C_YLW}?${C_RST} $1 ${C_DIM}[enter = yes · q = no]${C_RST} "
  IFS= read -rsn1 k </dev/tty || return 1
  _tui_out $'\n'
  [[ -z $k || $k == [yYsS] ]]
}
