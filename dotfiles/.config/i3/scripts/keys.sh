#!/usr/bin/env bash
# keys.sh — lista os bindsym do config do i3 no rofi (Super+/). Enter executa o atalho escolhido
cfg=~/.config/i3/config
list=$(awk '
  /^[[:space:]]*mode "/ { m=$0; sub(/^[[:space:]]*mode "/,"",m); sub(/".*/,"",m); if (m ~ /^\$/) m="sys"; next }
  /^[[:space:]]*}/      { m=""; next }
  /^[[:space:]]*bindsym/ {
    key=$2; $1=""; $2=""; cmd=$0; sub(/^ +/,"",cmd)
    sub(/^exec (--no-startup-id )?/,"",cmd)
    gsub(/\$mod/,"Super",key)
    if (m!="") key="[" m "] " key
    printf "%-28s %s\n", key, cmd
  }' "$cfg")
pick=$(printf '%s\n' "$list" | rofi -dmenu -i -p keys -theme ~/.config/rofi/underground.rasi \
  -theme-str 'window{width:900px;} listview{lines:18;} entry{placeholder:"procura um atalho_";}')
[[ -z $pick || $pick == \[* ]] && exit 0
cmd=$(awk -v k="${pick%% *}" '$1=="bindsym"{key=$2; gsub(/\$mod/,"Super",key); if(key==k){$1="";$2=""; sub(/^ +/,""); print; exit}}' "$cfg")
[[ -n $cmd ]] && i3-msg -q "$cmd"
