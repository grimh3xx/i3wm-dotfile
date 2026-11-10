#!/usr/bin/env bash
# Alt+v — histórico do clipboard (greenclip). Alt+Shift+v limpa
command -v greenclip >/dev/null || { notify-send -u critical clipboard "greenclip não instalado (paru -S rofi-greenclip)"; exit 1; }
[[ $1 == clear ]] && { greenclip clear; notify-send -a clipboard clipboard "histórico limpo"; exit 0; }
rofi -modi "clip:greenclip print" -show clip -run-command '{cmd}' -theme ~/.config/rofi/underground.rasi \
  -theme-str 'window{width:900px;} entry{placeholder:"clipboard_";}'
