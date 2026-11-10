# shellcheck shell=bash
# dotfiles.sh — installs dotfiles/ into $HOME, file by file.
#   link (default): symlink to the repo → `git pull` updates everything
#   copy (--copy): independent copies

dotfiles_install() {
  local src_root="$UG_ROOT/dotfiles" f rel dst n_new=0 n_same=0
  step "dotfiles → ~ (mode: $UG_MODE)"
  while IFS= read -r -d '' f; do
    rel=${f#"$src_root"/}
    dst="$HOME/$rel"
    if [[ $UG_MODE == link ]]; then
      if [[ -L $dst && $(readlink -- "$dst") == "$f" ]]; then n_same=$((n_same + 1)); continue; fi
    else
      if [[ -f $dst && ! -L $dst ]] && cmp -s -- "$f" "$dst"; then n_same=$((n_same + 1)); continue; fi
    fi
    backup_target "$rel"
    if ((UG_DRY)); then
      printf '   %s[dry-run]%s %s ~/%s\n' "$C_CYN" "$C_RST" "$UG_MODE" "$rel"
      n_new=$((n_new + 1)); continue
    fi
    run mkdir -p -- "$(dirname "$dst")"
    if [[ $UG_MODE == link ]]; then run ln -s -- "$f" "$dst"; else run cp -P -p -- "$f" "$dst"; fi
    # shellcheck disable=SC2088
    ((UG_DRY)) || info "~/$rel"
    n_new=$((n_new + 1))
  done < <(find "$src_root" \( -type f -o -type l \) -print0 | sort -z)
  ok "$n_new installed · $n_same already in place"
  [[ -d $UG_RUN_DIR/files ]] && info "previous files saved in $UG_RUN_DIR/files"

  # reload Xresources when running inside X
  if [[ -n ${DISPLAY:-} ]] && have xrdb; then run xrdb -merge "$HOME/.Xresources" || true; fi
  return 0
}
