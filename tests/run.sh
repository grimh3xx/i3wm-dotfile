#!/usr/bin/env bash
# tests/run.sh — runs everything in a throwaway $HOME. never touches your real $HOME.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/underground-i3"
pass=0 fail=0

t() {   # t "nome" comando...
  local name=$1; shift
  if "$@" >/tmp/ug-test.out 2>&1; then
    printf '  \e[32m✓\e[0m %s\n' "$name"; pass=$((pass + 1))
  else
    printf '  \e[31m✗\e[0m %s\n' "$name"; sed 's/^/      /' /tmp/ug-test.out | tail -20; fail=$((fail + 1))
  fi
}

fresh_home() {
  export HOME; HOME=$(mktemp -d)
  export XDG_STATE_HOME="$HOME/.local/state" XDG_DATA_HOME="$HOME/.local/share"
  unset DISPLAY
}

count_links() { find "$HOME" -type l -lname "$ROOT/dotfiles/*" | wc -l; }
n_dotfiles=$(find "$ROOT/dotfiles" \( -type f -o -type l \) | wc -l)

echo "== syntax"
for f in "$BIN" "$ROOT"/lib/*.sh "$ROOT"/tests/*.sh; do t "bash -n ${f#"$ROOT"/}" bash -n "$f"; done
if command -v shellcheck >/dev/null; then
  t "shellcheck (installer)" shellcheck -x "$BIN" "$ROOT"/lib/*.sh "$ROOT"/st/st-urls
  t "shellcheck (dotfile scripts)" shellcheck -S warning \
    "$ROOT"/dotfiles/.config/i3/scripts/*.sh "$ROOT"/dotfiles/.config/i3blocks/scripts/* \
    "$ROOT"/dotfiles/.config/fastfetch/logo.sh "$ROOT"/dotfiles/.config/lf/preview
fi
if command -v i3 >/dev/null; then
  t "i3 config is valid (i3 -C)" i3 -C -c "$ROOT/dotfiles/.config/i3/config"
fi

echo "== cli / tui"
t "menu has 9 components" bash -c "cd '$ROOT' && source lib/common.sh && source lib/packages.sh && eval \"\$(sed -n '/^components()/,/^}/p' underground-i3)\" && [[ \$(components | wc -l) -eq 9 ]]"
t "ANSI logo exists" test -s "$ROOT/assets/logo.ans"
t "--help"    "$BIN" --help
t "--version" "$BIN" --version
t "unknown option fails" bash -c "! '$BIN' --nao-existe"
t "unknown command fails" bash -c "! '$BIN' --yes nao-existe"

echo "== dry-run changes nothing"
fresh_home
t "dry-run dotfiles" "$BIN" --dry-run --yes dotfiles
t "  … \$HOME is still empty" bash -c "[[ -z \$(find '$HOME' -mindepth 1 -print -quit) ]]"

echo "== dotfiles (symlink) + idempotence"
fresh_home
t "install" "$BIN" --yes dotfiles
t "  … every file is a link ($n_dotfiles)" bash -c "[[ \$(find '$HOME' -type l -lname '$ROOT/dotfiles/*' | wc -l) -eq $n_dotfiles ]]"
t "  … second run changes nothing" bash -c "'$BIN' --yes dotfiles | grep -q '0 installed'"

echo "== backup + restore"
fresh_home
mkdir -p "$HOME/.config/i3"; echo "old config" >"$HOME/.config/i3/config"
t "install over an existing config" "$BIN" --yes dotfiles
t "  … old config went to the backup" bash -c "grep -rq 'old config' '$XDG_STATE_HOME/underground-i3/backups'"
t "restore --list" bash -c "'$BIN' restore --list | grep -q files"
t "restore latest" "$BIN" --yes restore latest
t "  … old config is back" bash -c "[[ \$(cat '$HOME/.config/i3/config') == 'old config' ]]"
t "  … no links left behind" bash -c "[[ \$(find '$HOME' -type l | wc -l) -eq 0 ]]"

echo "== copy mode"
fresh_home
t "install with --copy" "$BIN" --yes --copy dotfiles
t "  … no symlinks" bash -c "[[ \$(find '$HOME' -type l | wc -l) -eq 0 ]]"
t "  … scripts are still executable" test -x "$HOME/.config/i3/scripts/lock.sh"

echo "== dry-run of the full profile (no network, no root)"
fresh_home
t "install full --dry-run" "$BIN" --dry-run --yes install full

echo "== privacy: nothing personal in the repo"
t "no hardcoded /home/<user>" bash -c "! grep -rIn '/home/[a-z]' '$ROOT/dotfiles' '$ROOT/lib' '$ROOT/underground-i3' '$ROOT/tools' | grep -v '/home/you'"
t "no symlinks inside dotfiles/" bash -c "[[ -z \$(find '$ROOT/dotfiles' -type l -print -quit) ]]"

echo
printf '%d passed · %d failed\n' "$pass" "$fail"
((fail == 0))
