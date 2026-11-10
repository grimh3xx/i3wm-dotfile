# shellcheck shell=bash
# doctor.sh — checks that everything is in place (read-only)

doctor() {
  step "doctor"
  local bad=0 c f
  _chk() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else err "$1"; bad=$((bad + 1)); fi; }

  for c in i3 i3blocks rofi dunst picom feh xss-lock i3lock maim xclip pamixer playerctl jq fastfetch chafa starship; do
    _chk "$c" "have $c"
  done
  _chk "st in ~/.local/bin" "[[ -x $HOME/.local/bin/st ]]"
  _chk "terminfo st-256color" "infocmp st-256color"
  # shellcheck disable=SC2088
  _chk "~/.local/bin on PATH (zshenv)" "zsh -c 'command -v st'"
  _chk "font: CaskaydiaCove Nerd Font" "fc-list | grep -qi 'CaskaydiaCove'"
  _chk "i3 login session (xsessions)" "[[ -f /usr/share/xsessions/i3.desktop ]]"
  _chk "i3 config is valid" "i3 -C -c $HOME/.config/i3/config"
  _chk "wallpaper" "[[ -e $HOME/.config/i3/wallpaper ]]"
  _chk "greenclip (clipboard)" "have greenclip"

  for f in .config/i3/config .config/i3blocks/config .config/rofi/underground.rasi .xprofile .Xresources; do
    [[ -e $HOME/$f ]] || { err "missing ~/$f"; bad=$((bad + 1)); }
  done

  if has_nvidia; then _chk "nvidia-settings (G-Sync)" "have nvidia-settings"; fi
  if ((bad)); then warn "$bad problem(s). run: underground-i3 install"; return 1; fi
  ok "all good. expect us."
}
