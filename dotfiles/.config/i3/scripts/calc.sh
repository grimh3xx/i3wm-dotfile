#!/bin/sh
exec rofi -show calc -modi calc -no-show-match -no-sort \
  -calc-command "echo -n '{result}' | xclip -sel clip" \
  -theme ~/.config/rofi/underground.rasi \
  -theme-str 'entry{placeholder:"2+2, 10 usd to brl, 5 km to mi_";}'
