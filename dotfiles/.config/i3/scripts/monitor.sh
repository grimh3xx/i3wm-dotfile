#!/bin/sh
# monitor principal na resolução nativa e na MAIOR taxa de atualização disponível.
# NVIDIA: liga G-Sync compatível. o nome da saída (DP-0, HDMI-1...) é detectado sozinho.
# pra forçar: UG_OUTPUT=DP-2 UG_MODE=3440x1440 no ~/.xprofile
command -v xrandr >/dev/null || exit 0

# shellcheck disable=SC2046  # split intencional: "saída modo taxa"
set -- $(xrandr | awk -v want_out="$UG_OUTPUT" -v want_mode="$UG_MODE" '
  / connected/ {
    out = $1
    ok = (want_out == "" || out == want_out)
    if (ok && !first) first = out
    if (ok && $3 == "primary") prim = out
    next
  }
  / disconnected/ { out = ""; next }
  out && /^ +[0-9]+x[0-9]+/ {
    mode = $1
    if (!(out in nat)) nat[out] = mode                  # 1ª linha = resolução nativa
    target = (want_mode != "") ? want_mode : nat[out]
    if (mode != target) next
    for (i = 2; i <= NF; i++) { r = $i; gsub(/[*+]/, "", r)
      if (r + 0 > best[out]) { best[out] = r + 0; rate[out] = r; md[out] = mode } }
  }
  END { o = prim ? prim : first; if (o && md[o]) print o, md[o], rate[o] }')
[ -n "$1" ] || exit 0
out=$1 mode=$2 rate=$3

if command -v nvidia-settings >/dev/null && nvidia-settings -q gpus >/dev/null 2>&1; then
  hz=$(printf '%.0f' "$rate")
  nvidia-settings --assign CurrentMetaMode="$out: ${mode}_$hz +0+0 {AllowGSYNCCompatible=On}" >/dev/null 2>&1 \
    || xrandr --output "$out" --mode "$mode" --rate "$rate"
  xrandr --output "$out" --primary
else
  xrandr --output "$out" --primary --mode "$mode" --rate "$rate"
fi
