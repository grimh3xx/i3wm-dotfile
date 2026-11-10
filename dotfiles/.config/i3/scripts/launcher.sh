#!/bin/sh
# rofi launcher (i3 splits commands on commas, so it lives here)
exec rofi -show combi -modes combi -combi-modes "drun,window,run" \
  -combi-display-format "{text}" -theme ~/.config/rofi/underground.rasi
