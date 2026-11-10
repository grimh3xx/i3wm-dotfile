#!/usr/bin/env bash
# picks a random logo (linus / anon / fsociety) and runs fastfetch.
# kitty shows the real picture; st and other terminals get unicode blocks (chafa)
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
