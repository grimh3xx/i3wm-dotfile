#!/usr/bin/env bash
# pula pro primeiro workspace vazio (1-20). com "move", leva a janela junto
used=$(i3-msg -t get_workspaces | jq '.[].num')
for n in $(seq 1 20); do
  grep -qx "$n" <<<"$used" && continue
  [[ $1 == move ]] && i3-msg -q "move container to workspace number $n"
  i3-msg -q "workspace number $n"; exit 0
done
