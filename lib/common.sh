# shellcheck shell=bash disable=SC2034
# common.sh — colors, logging, dry-run, prompts

UG_VERSION="1.0.0"
UG_DRY=0
UG_YES=0
UG_MODE="link"          # link | copy
UG_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/underground-i3"
UG_LOG="$UG_STATE/underground-i3.log"

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  C_RST=$'\e[0m' C_DIM=$'\e[90m' C_RED=$'\e[31m' C_GRN=$'\e[32m'
  C_YLW=$'\e[33m' C_BLU=$'\e[34m' C_CYN=$'\e[36m' C_BLD=$'\e[1m'
else
  C_RST="" C_DIM="" C_RED="" C_GRN="" C_YLW="" C_BLU="" C_CYN="" C_BLD=""
fi

no_color() { C_RST="" C_DIM="" C_RED="" C_GRN="" C_YLW="" C_BLU="" C_CYN="" C_BLD=""; }

_log() {
  ((UG_DRY)) && return 0
  mkdir -p "$UG_STATE" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$UG_LOG" 2>/dev/null || true
}

step() { printf '\n%s::%s %s%s%s\n' "$C_BLU" "$C_RST" "$C_BLD" "$*" "$C_RST"; _log "STEP $*"; }
info() { printf '   %s%s%s\n' "$C_DIM" "$*" "$C_RST"; }
ok()   { printf '   %s✓%s %s\n' "$C_GRN" "$C_RST" "$*"; _log "OK $*"; }
warn() { printf '   %s!%s %s\n' "$C_YLW" "$C_RST" "$*" >&2; _log "WARN $*"; }
err()  { printf '   %s✗%s %s\n' "$C_RED" "$C_RST" "$*" >&2; _log "ERR $*"; }
die()  { err "$*"; exit 1; }

# run CMD... — runs it, or only prints it with --dry-run
run() {
  if ((UG_DRY)); then
    printf '   %s[dry-run]%s %s\n' "$C_CYN" "$C_RST" "$*"
    return 0
  fi
  _log "RUN $*"
  "$@"
}

# ask "question" — yes/no. --yes and --dry-run answer yes (dry-run only prints the plan)
ask() {
  ((UG_YES || UG_DRY)) && return 0
  local a
  read -r -p "   ${C_YLW}?${C_RST} $1 [y/N] " a </dev/tty || return 1
  [[ $a =~ ^[yYsS] ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

# package list from a file (skips comments and blank lines)
read_list() { grep -vE '^\s*(#|$)' "$1" | awk '{print $1}'; }

banner() {
  printf '%s' "$C_BLU"
  cat <<'EOF'
   _   _           _                                           _ ___ _____
  | | | |_ __   __| | ___ _ __ __ _ _ __ ___  _   _ _ __   __| |_ _|___ /
  | | | | '_ \ / _` |/ _ \ '__/ _` | '__/ _ \| | | | '_ \ / _` || |  |_ \
  | |_| | | | | (_| |  __/ | | (_| | | | (_) | |_| | | | | (_| || | ___) |
   \___/|_| |_|\__,_|\___|_|  \__, |_|  \___/ \__,_|_| |_|\__,_|___|____/
                              |___/
EOF
  printf '%s  [anon]%s we do not forgive. we do not forget. %sexpect us.%s\n' "$C_BLU" "$C_DIM" "$C_RST" "$C_RST"
}
