#!/usr/bin/env bash
# Alt+v — clipboard history (greenclip). Alt+Shift+v clears it
command -v greenclip >/dev/null || { notify-send -u critical clipboard "greenclip is not installed (paru -S rofi-greenclip)"; exit 1; }
[[ $1 == clear ]] && { greenclip clear; notify-send -a clipboard clipboard "history cleared"; exit 0; }
rofi -modi "clip:greenclip print" -show clip -run-command '{cmd}' -theme ~/.config/rofi/underground.rasi \
  -theme-str 'window{width:900px;} entry{placeholder:"clipboard_";}'
