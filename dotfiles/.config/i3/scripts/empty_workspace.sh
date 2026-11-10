#!/usr/bin/env bash
# jump to the first empty workspace (1-20). with "move", the focused window comes along
used=$(i3-msg -t get_workspaces | jq '.[].num')
for n in $(seq 1 20); do
  grep -qx "$n" <<<"$used" && continue
  [[ $1 == move ]] && i3-msg -q "move container to workspace number $n"
  i3-msg -q "workspace number $n"; exit 0
done
