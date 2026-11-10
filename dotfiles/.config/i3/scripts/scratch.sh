#!/usr/bin/env bash
# scratch.sh <nome> <comando...> — mostra/esconde o dropdown <nome>; se não existir, abre no st
name=$1; shift
if i3-msg -t get_tree | grep -q "\"instance\":\"$name\""; then
  i3-msg -q "[instance=\"^$name\$\"] scratchpad show"
else
  exec st -n "$name" -t "$name" -e sh -c "$*"
fi
