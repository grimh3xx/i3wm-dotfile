# shellcheck shell=bash
# assets.sh — fastfetch logos and a default wallpaper
#
# the Anonymous mask (CC BY-SA 4.0) ships with the repo. the Linus frame (Aalto University
# talk, 2012) and the fsociety mask (Mr. Robot) are copyrighted, so they are NOT in the
# repo: they are downloaded and processed on your machine, only if you agree.

LOGO_DIR="$HOME/.config/fastfetch/logos"
WALL_DIR="$HOME/Pictures/Wallpapers"

_dl() { curl -fsSL --max-time 30 -A "Mozilla/5.0" -o "$2" "$1"; }

_duotone() {   # image → underground palette (black / dark blue / arch blue / white)
  local clut
  clut=$(mktemp --suffix=.png)
  magick -size 1x64 xc:'#101014' -size 1x64 xc:'#164a66' -size 1x64 xc:'#1793d1' \
         -size 1x64 xc:'#e8e8ee' -append "$clut"
  magick "$1" -colorspace gray -sigmoidal-contrast 6x50% -posterize 4 "$clut" -clut "$2"
  rm -f "$clut"
}

assets_logos() {
  step "fastfetch logos"
  run mkdir -p "$LOGO_DIR"
  run cp "$UG_ROOT/assets/logos/anon.png" "$LOGO_DIR/anon.png"
  ok "anon (Guy Fawkes, CC BY-SA 4.0)"

  have magick || { warn "imagemagick missing — skipping linus/fsociety"; return 0; }
  ask "also download Linus (NVIDIA finger, 2012) and the fsociety mask? (copyrighted, personal use)" || return 0
  local tmp
  tmp=$(mktemp -d)
  if ((UG_DRY)); then
    info "[dry-run] would download linus09.jpg (gigazine) and wp2678303.jpg (wallpapercave)"
  else
    if _dl "https://i.gzn.jp/img/2012/06/18/linus-nvidia-f-word/linus09.jpg" "$tmp/linus.jpg"; then
      magick "$tmp/linus.jpg" -crop 560x560+400+0 +repage -resize 600x600 "$tmp/linus-c.png"
      _duotone "$tmp/linus-c.png" "$LOGO_DIR/linus.png" && ok "linus"
    else warn "could not download the Linus frame"; fi
    if _dl "https://wallpapercave.com/wp/wp2678303.jpg" "$tmp/fs.jpg"; then
      magick "$tmp/fs.jpg" -crop 360x470+780+335 +repage -level 8%,35% -resize 500x "$LOGO_DIR/fsociety.png" && ok "fsociety"
    else warn "could not download the fsociety mask"; fi
  fi
  rm -rf "$tmp"
}

_screen_size() {
  if [[ -n ${DISPLAY:-} ]] && have xrandr; then
    xrandr 2>/dev/null | awk '/ connected/{c=1;next} c&&/^ +[0-9]+x[0-9]+/{print $1; exit}'
  fi
}

assets_wallpaper() {
  step "wallpaper"
  local link="$HOME/.config/i3/wallpaper" size out
  if [[ -e $link ]]; then ok "already set ($(readlink -f "$link"))"; return 0; fi
  have magick || { warn "imagemagick missing — no default wallpaper"; return 0; }
  size=$(_screen_size); size=${size:-2560x1440}
  out="$WALL_DIR/underground-$size.png"
  run mkdir -p "$WALL_DIR" "$(dirname "$link")"
  if ((UG_DRY)); then
    info "[dry-run] would generate $out"
  else
    local font
    font=$(fc-match -f '%{file}' 'CaskaydiaCove Nerd Font Mono:bold' 2>/dev/null)
    magick -size "$size" xc:'#101014' \( +clone +noise Random -colorspace gray -evaluate multiply 0.06 \) \
      -compose plus -composite -gravity center ${font:+-font "$font"} \
      -fill '#1793d1' -pointsize 22 -annotate +0-40 '[ anon ]' \
      -fill '#26272f' -pointsize 54 -annotate +0+20 'expect us.' "$out"
  fi
  run ln -sfn "$out" "$link"
  _manifest created ".config/i3/wallpaper"
  ok "wallpaper generated ($size) — change it with Alt+Shift+w"
}
