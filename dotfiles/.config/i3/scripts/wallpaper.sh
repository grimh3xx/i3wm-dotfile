#!/usr/bin/env bash
# Alt+Shift+w — pick a wallpaper (with thumbnails) from ~/Pictures/Wallpapers. saved as ~/.config/i3/wallpaper
dir=~/Pictures/Wallpapers
pick=$(find "$dir" -maxdepth 2 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%f\000icon\037%p\n' | sort \
  | rofi -dmenu -i -p wall -show-icons -theme ~/.config/rofi/underground.rasi \
      -theme-str 'window{width:1100px;} listview{columns:4; lines:3;} element{orientation:vertical; padding:8px;} element-icon{size:200px;} element-text{horizontal-align:0.5;} entry{placeholder:"wallpaper_";}') || exit 0
file=$(find "$dir" -maxdepth 2 -type f -name "$pick" | head -1)
[[ -f $file ]] || exit 0
ln -sfn "$file" ~/.config/i3/wallpaper
feh --no-fehbg --bg-fill ~/.config/i3/wallpaper
notify-send -a wallpaper "wallpaper" "$pick"
