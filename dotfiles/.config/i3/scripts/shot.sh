#!/bin/sh
# shot.sh [full|area]
mkdir -p ~/Pictures/Screenshots
f=~/Pictures/Screenshots/$(date +%F_%H-%M-%S).png
if [ "$1" = area ]; then maim -s -c 0.09,0.58,0.82 "$f"; else maim "$f"; fi && xclip -sel clip -t image/png "$f"
