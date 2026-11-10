#!/usr/bin/env bash
# Alt+o — web search. prefixes: g google · aw arch wiki · aur · yt youtube · gh github · w wikipedia · (none) duckduckgo
help="g <term>   google
aw <term>  arch wiki
aur <pkg>  aur
yt <term>  youtube
gh <term>  github
w <term>   wikipedia
<term>     duckduckgo"
q=$(printf '%s\n' "$help" | rofi -dmenu -i -p web -theme ~/.config/rofi/underground.rasi \
  -theme-str 'entry{placeholder:"search the web_";} listview{lines:7;}' ) || exit 0
[[ -z $q ]] && exit 0
# picking one of the help lines does nothing
grep -qxF -- "$q" <<<"$help" && exit 0
pre=${q%% *}; rest=${q#* }; [[ $rest == "$q" ]] && rest=""
enc() { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote_plus(sys.argv[1]))' "$1"; }
case $pre in
  g)   url="https://www.google.com/search?q=$(enc "$rest")" ;;
  aw)  url="https://wiki.archlinux.org/index.php?search=$(enc "$rest")" ;;
  aur) url="https://aur.archlinux.org/packages?K=$(enc "$rest")" ;;
  yt)  url="https://www.youtube.com/results?search_query=$(enc "$rest")" ;;
  gh)  url="https://github.com/search?q=$(enc "$rest")" ;;
  w)   url="https://en.wikipedia.org/w/index.php?search=$(enc "$rest")" ;;
  *)   url="https://duckduckgo.com/?q=$(enc "$q")" ;;
esac
setsid -f xdg-open "$url" >/dev/null 2>&1
