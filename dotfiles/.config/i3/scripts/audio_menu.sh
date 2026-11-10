#!/usr/bin/env bash
# rofi: pick the audio output (headset, speakers, hdmi...) and move whatever is playing to it
def=$(pactl get-default-sink)
mapfile -t names < <(pactl -f json list sinks | jq -r '.[].name')
mapfile -t descs < <(pactl -f json list sinks | jq -r '.[].description')
menu=""
for i in "${!names[@]}"; do
  mark="  "; [[ ${names[$i]} == "$def" ]] && mark="● "
  menu+="$mark${descs[$i]}"$'\n'
done
pick=$(printf '%s' "$menu" | rofi -dmenu -i -p audio -format i -theme ~/.config/rofi/underground.rasi \
  -theme-str 'entry{placeholder:"audio output_";} listview{lines:6;}')
[[ -z $pick ]] && exit 0
sink=${names[$pick]}
pactl set-default-sink "$sink"
for s in $(pactl list short sink-inputs | cut -f1); do pactl move-sink-input "$s" "$sink"; done
notify-send -a audio "audio output" "${descs[$pick]}"
pkill -RTMIN+10 i3blocks
