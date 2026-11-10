#!/usr/bin/env bash
# Alt+Shift+e — menu de energia
opts="  lock\n󰍃  logout\n󰒲  suspend\n  reboot\n⏻  poweroff"
pick=$(printf "$opts" | rofi -dmenu -i -p power -theme ~/.config/rofi/underground.rasi \
  -theme-str 'window{width:360px;} listview{lines:5;} textbox-motto{str:"expect us.";} entry{placeholder:"_";}') || exit 0
confirm() { [[ $(printf 'não\nsim' | rofi -dmenu -p "$1?" -theme ~/.config/rofi/underground.rasi -theme-str 'window{width:300px;} listview{lines:2;}') == sim ]]; }
case $pick in
  *lock)     ~/.config/i3/scripts/lock.sh ;;
  *logout)   confirm logout   && i3-msg exit ;;
  *suspend)  systemctl suspend ;;
  *reboot)   confirm reboot   && systemctl reboot ;;
  *poweroff) confirm poweroff && systemctl poweroff ;;
esac
