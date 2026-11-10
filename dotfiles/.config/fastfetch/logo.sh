#!/usr/bin/env bash
# sorteia um logo (linus / anon / fsociety) e roda o fastfetch.
# kitty mostra a foto de verdade; st e o resto mostram em blocos (chafa)
L=~/.config/fastfetch/logos
shopt -s nullglob
pics=("$L"/*.png)
(( ${#pics[@]} )) || exec fastfetch "$@"
pic=${pics[RANDOM % ${#pics[@]}]}
if [[ $TERM == xterm-kitty ]]; then
  exec fastfetch --logo-type kitty-direct --logo "$pic" "$@"
else
  exec fastfetch --logo-type chafa --logo "$pic" "$@"
fi
