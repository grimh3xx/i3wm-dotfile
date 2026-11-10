# shellcheck shell=bash
# st.sh — fetches upstream st 0.9.2, applies the underground patch and installs to ~/.local (no root)
#
# patches included (one diff, conflicts already resolved):
#   scrollback + scrollback-mouse · boxdraw · glyph-wide-support · xresources-with-reload-signal
#   clipboard · newterm · externalpipe · bold-is-not-bright

ST_TAG="0.9.2"
ST_SRC="${XDG_DATA_HOME:-$HOME/.local/share}/underground-i3/st"

st_install() {
  step "st $ST_TAG (suckless) + patches underground"
  local p
  for p in git make cc pkg-config; do
    have "$p" && continue
    ((UG_DRY)) && { warn "needs '$p' (base-devel/git) — installed by the core step"; continue; }
    die "needs '$p' (install base-devel and git)"
  done

  if [[ -d $ST_SRC/.git ]]; then
    run git -C "$ST_SRC" fetch -q --depth 1 origin "refs/tags/$ST_TAG:refs/tags/$ST_TAG"
    run git -C "$ST_SRC" checkout -q -f "$ST_TAG"
    run git -C "$ST_SRC" clean -qfdx
  else
    run mkdir -p "$(dirname "$ST_SRC")"
    run git clone -q --branch "$ST_TAG" --depth 1 https://git.suckless.org/st "$ST_SRC"
  fi
  run git -C "$ST_SRC" apply "$UG_ROOT/st/st-underground-$ST_TAG.diff"
  run cp "$UG_ROOT/st/config.h" "$ST_SRC/config.h"
  run make -s -C "$ST_SRC" PREFIX="$HOME/.local"
  run make -s -C "$ST_SRC" PREFIX="$HOME/.local" install
  run install -Dm755 "$UG_ROOT/st/st-urls" "$HOME/.local/bin/st-urls"
  ok "st installed to ~/.local/bin/st (terminfo in ~/.terminfo)"
}
