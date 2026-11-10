# shellcheck shell=bash
# backup.sh — keeps everything that gets replaced, so a whole run can be undone.
#
# each run becomes $UG_STATE/backups/<id>/ with:
#   files/<path relative to $HOME>   what existed before
#   manifest                         one line per action: "backup <rel>" or "created <rel>"

UG_RUN_ID="$(date +%Y%m%d-%H%M%S)"
UG_RUN_DIR="$UG_STATE/backups/$UG_RUN_ID"

_manifest() {
  ((UG_DRY)) && return 0
  mkdir -p "$UG_RUN_DIR"
  printf '%s %s\n' "$1" "$2" >>"$UG_RUN_DIR/manifest"
}

# backup_target REL — moves $HOME/REL into the backup (if it exists) and records it
backup_target() {
  local rel=$1 src="$HOME/$1"
  [[ -e $src || -L $src ]] || { _manifest created "$rel"; return 0; }
  if ((UG_DRY)); then
    printf '   %s[dry-run]%s backup ~/%s\n' "$C_CYN" "$C_RST" "$rel"
    return 0
  fi
  mkdir -p "$UG_RUN_DIR/files/$(dirname "$rel")"
  mv -- "$src" "$UG_RUN_DIR/files/$rel"
  _manifest backup "$rel"
}

restore_list() {
  local d
  [[ -d $UG_STATE/backups ]] || { info "no runs recorded"; return 0; }
  for d in "$UG_STATE"/backups/*/; do
    [[ -f $d/manifest ]] || continue
    printf '   %s  %s%s files%s\n' "$(basename "$d")" "$C_DIM" "$(wc -l <"$d/manifest")" "$C_RST"
  done
}

# restore ID|latest — undoes a run: removes what it created and puts the backups back
restore_run() {
  local id=${1:-latest} dir action rel
  if [[ $id == latest ]]; then
    id=$(find "$UG_STATE/backups" -mindepth 1 -maxdepth 1 -type d ! -name '*.restored' -printf '%f\n' 2>/dev/null | sort | tail -1)
    [[ -n $id ]] || die "nothing to restore"
  fi
  dir="$UG_STATE/backups/$id"
  [[ -f $dir/manifest ]] || die "run '$id' not found (see: restore --list)"
  step "restoring $id"
  ask "undo run $id?" || { info "cancelled"; return 0; }
  # reverse order
  tac "$dir/manifest" | while read -r action rel; do
    case $action in
      created)
        if [[ -L $HOME/$rel || -f $HOME/$rel ]]; then run rm -f -- "$HOME/$rel"; ok "removed ~/$rel"; fi ;;
      backup)
        run rm -rf -- "$HOME/$rel"
        run mkdir -p "$(dirname "$HOME/$rel")"
        run mv -- "$dir/files/$rel" "$HOME/$rel"
        ok "restored ~/$rel" ;;
    esac
  done
  ((UG_DRY)) || mv -- "$dir" "$dir.restored"
  ok "done. run $id was undone"
}
