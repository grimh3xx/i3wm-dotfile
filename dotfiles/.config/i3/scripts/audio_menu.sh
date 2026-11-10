#!/usr/bin/env bash
# rofi: escolhe a saída de áudio (fone, caixa, hdmi...) e move o que está tocando pra ela
def=$(pactl get-default-sink)
mapfile -t names < <(pactl -f json list sinks | jq -r '.[].name')
mapfile -t descs < <(pactl -f json list sinks | jq -r '.[].description')
menu=""
for i in "${!names[@]}"; do
  mark="  "; [[ ${names[$i]} == "$def" ]] && mark="● "
  menu+="$mark${descs[$i]}"$'\n'
done
pick=$(printf '%s' "$menu" | rofi -dmenu -i -p audio -format i -theme ~/.config/rofi/underground.rasi \
  -theme-str 'entry{placeholder:"saída de áudio_";} listview{lines:6;}')
[[ -z $pick ]] && exit 0
sink=${names[$pick]}
pactl set-default-sink "$sink"
for s in $(pactl list short sink-inputs | cut -f1); do pactl move-sink-input "$s" "$sink"; done
notify-send -a audio "saída de áudio" "${descs[$pick]}"
pkill -RTMIN+10 i3blocks
