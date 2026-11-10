#!/usr/bin/env bash
# UNDERGROUND // lock — pixelated, darkened screenshot with the quote. -n = wait for unlock (xss-lock)
img=/tmp/i3lock-$UID.png
font=$(fc-match -f '%{file}' 'CaskaydiaCove Nerd Font Mono:bold')
maim -u "$img" 2>/dev/null || { exec i3lock "$@" -c 101014; }
magick "$img" -scale 5% -scale 2000% -fill '#101014' -colorize 55% \
  -gravity center -font "$font" \
  -fill '#1793d1' -pointsize 26 -annotate +0-330 '[ anon ]' \
  -fill '#ffffff' -pointsize 64 -annotate +0-260 'expect us.' \
  -fill '#6b6c78' -pointsize 20 -annotate +0-200 'we are anonymous. we are legion. we do not forgive. we do not forget.' \
  "$img"
exec i3lock "$@" -e -f -i "$img"
