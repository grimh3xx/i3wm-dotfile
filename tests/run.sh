#!/usr/bin/env bash
# tests/run.sh — roda tudo num $HOME temporário. não toca no seu $HOME de verdade.
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

echo "== sintaxe"
for f in "$BIN" "$ROOT"/lib/*.sh "$ROOT"/tests/*.sh; do t "bash -n ${f#"$ROOT"/}" bash -n "$f"; done
if command -v shellcheck >/dev/null; then
  t "shellcheck (instalador)" shellcheck -x "$BIN" "$ROOT"/lib/*.sh "$ROOT"/st/st-urls
  t "shellcheck (scripts dos dotfiles)" shellcheck -S warning \
    "$ROOT"/dotfiles/.config/i3/scripts/*.sh "$ROOT"/dotfiles/.config/i3blocks/scripts/* \
    "$ROOT"/dotfiles/.config/fastfetch/logo.sh "$ROOT"/dotfiles/.config/lf/preview
fi
if command -v i3 >/dev/null; then
  t "config do i3 válida (i3 -C)" i3 -C -c "$ROOT/dotfiles/.config/i3/config"
fi

echo "== cli / tui"
t "componentes do menu (9)" bash -c "cd '$ROOT' && source lib/common.sh && source lib/packages.sh && eval \"\$(sed -n '/^components()/,/^}/p' underground-i3)\" && [[ \$(components | wc -l) -eq 9 ]]"
t "logo ANSI existe" test -s "$ROOT/assets/logo.ans"
t "--help"    "$BIN" --help
t "--version" "$BIN" --version
t "opção inválida falha" bash -c "! '$BIN' --nao-existe"
t "comando inválido falha" bash -c "! '$BIN' --yes nao-existe"

echo "== dry-run não altera nada"
fresh_home
t "dry-run dotfiles" "$BIN" --dry-run --yes dotfiles
t "  … \$HOME continua vazio" bash -c "[[ -z \$(find '$HOME' -mindepth 1 -print -quit) ]]"

echo "== dotfiles (symlink) + idempotência"
fresh_home
t "instala" "$BIN" --yes dotfiles
t "  … todos os arquivos viraram links ($n_dotfiles)" bash -c "[[ \$(find '$HOME' -type l -lname '$ROOT/dotfiles/*' | wc -l) -eq $n_dotfiles ]]"
t "  … 2ª execução não muda nada" bash -c "'$BIN' --yes dotfiles | grep -q '0 installed'"

echo "== backup + restore"
fresh_home
mkdir -p "$HOME/.config/i3"; echo "config antiga" >"$HOME/.config/i3/config"
t "instala por cima de config existente" "$BIN" --yes dotfiles
t "  … config antiga foi pro backup" bash -c "grep -rq 'config antiga' '$XDG_STATE_HOME/underground-i3/backups'"
t "restore --list" bash -c "'$BIN' restore --list | grep -q files"
t "restore latest" "$BIN" --yes restore latest
t "  … config antiga voltou" bash -c "[[ \$(cat '$HOME/.config/i3/config') == 'config antiga' ]]"
t "  … nenhum link sobrou" bash -c "[[ \$(find '$HOME' -type l | wc -l) -eq 0 ]]"

echo "== modo cópia"
fresh_home
t "instala com --copy" "$BIN" --yes --copy dotfiles
t "  … nenhum symlink" bash -c "[[ \$(find '$HOME' -type l | wc -l) -eq 0 ]]"
t "  … scripts continuam executáveis" test -x "$HOME/.config/i3/scripts/lock.sh"

echo "== dry-run do perfil full (sem rede, sem root)"
fresh_home
t "install full --dry-run" "$BIN" --dry-run --yes install full

echo "== segurança: nada pessoal no repo"
t "sem /home/<usuário> fixo" bash -c "! grep -rIn '/home/[a-z]' '$ROOT/dotfiles' '$ROOT/lib' '$ROOT/underground-i3' '$ROOT/tools' | grep -v '/home/you'"
t "nenhum symlink dentro de dotfiles/" bash -c "[[ -z \$(find '$ROOT/dotfiles' -type l -print -quit) ]]"

echo
printf '%d ok · %d falha(s)\n' "$pass" "$fail"
((fail == 0))
