# shellcheck shell=bash
# packages.sh — pacman for the official repos, paru/yay for the AUR (always as your user)

aur_helper() {
  if have paru; then echo paru; elif have yay; then echo yay; else return 1; fi
}

has_nvidia() {
  have lspci && lspci 2>/dev/null | grep -iE 'vga|3d' | grep -qi nvidia
}

pkgs_missing() {
  local p
  for p in "$@"; do pacman -Q "$p" >/dev/null 2>&1 || printf '%s\n' "$p"; done
}

pkgs_repo() {
  local list=$1 missing
  [[ -f $list ]] || die "list not found: $list"
  local -a want
  mapfile -t want < <(read_list "$list")
  mapfile -t missing < <(pkgs_missing "${want[@]}")
  if ((${#missing[@]} == 0)); then ok "$(basename "$list" .txt): all installed"; return 0; fi
  info "$(basename "$list" .txt): ${missing[*]}"
  run sudo pacman -S --needed --noconfirm "${missing[@]}"
}

install_aur_helper() {
  aur_helper >/dev/null && return 0
  warn "no AUR helper (paru/yay) found"
  ask "install paru-bin now?" || return 1
  local tmp
  tmp=$(mktemp -d)
  run git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  ( cd "$tmp/paru-bin" && run makepkg -si --noconfirm )
  rm -rf "$tmp"
}

pkgs_aur() {
  local list="$UG_ROOT/packages/aur.txt" missing helper
  local -a want
  mapfile -t want < <(read_list "$list")
  mapfile -t missing < <(pkgs_missing "${want[@]}")
  if ((${#missing[@]} == 0)); then ok "aur: all installed"; return 0; fi
  install_aur_helper || { warn "skipping AUR: ${missing[*]}"; return 0; }
  helper=$(aur_helper || echo paru)
  info "aur ($helper): ${missing[*]}"
  run "$helper" -S --needed --noconfirm "${missing[@]}"
}

# packages_install [core|apps|aur|nvidia|all]...
packages_install() {
  local sets=("$@") s
  ((${#sets[@]})) || sets=(core)
  [[ ${sets[*]} == *all* ]] && sets=(core apps aur nvidia)
  have pacman || die "pacman not found — this is for Arch Linux"
  step "packages: ${sets[*]}"
  for s in "${sets[@]}"; do
    case $s in
      core|apps) pkgs_repo "$UG_ROOT/packages/$s.txt" ;;
      aur)       pkgs_aur ;;
      nvidia)    if has_nvidia; then pkgs_repo "$UG_ROOT/packages/nvidia.txt"; else info "no NVIDIA GPU — skipping"; fi ;;
      *)         die "unknown package set: $s" ;;
    esac
  done
}
