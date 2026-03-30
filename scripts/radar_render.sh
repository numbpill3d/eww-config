#!/usr/bin/env bash
# radar_render.sh — generate radar PNG for eww image widget
# echoes the PNG path; called by defpoll radar_img

OUT="/tmp/eww_radar.png"
RADAR_C=76

coords() {
  local mac="$1" dist="$2"
  local h angle
  h=$(printf '%s' "$mac" | md5sum)
  angle=$(( 16#${h:0:4} % 360 ))
  awk -v a="$angle" -v d="$dist" -v c="$RADAR_C" 'BEGIN {
    pi = 3.14159265358979
    r  = a * pi / 180
    x  = int(c + d * sin(r) + 0.5)
    y  = int(c - d * cos(r) + 0.5)
    if (x < 4)   x = 4
    if (x > 148) x = 148
    if (y < 4)   y = 4
    if (y > 148) y = 148
    print x, y
  }'
}

# --- collect arp devices ---
declare -a DEVICES
count=0

while IFS= read -r line; do
  (( count >= 8 )) && break
  mac=$(awk '{for(i=1;i<=NF;i++) if($i=="lladdr"){print $(i+1); exit}}' <<< "$line")
  state=$(awk '{print $NF}' <<< "$line")
  [[ -z "$mac" ]] && continue
  [[ ! "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] && continue
  h=$(printf '%s' "$mac" | md5sum)
  base=$(( 16#${h:4:4} % 18 ))
  case "$state" in
    REACHABLE|DELAY|PROBE) dist=$(( 15 + base )) ;;
    STALE)                 dist=$(( 45 + base )) ;;
    *)                     dist=$(( 32 + base )) ;;
  esac
  read -r x y <<< "$(coords "$mac" "$dist")"
  DEVICES+=("$x $y arp ${state,,}")
  (( count++ ))
done < <(ip neigh show 2>/dev/null | grep -E 'REACHABLE|STALE|DELAY|PROBE')

# --- collect bluetooth devices (timeout entire section) ---
if command -v bluetoothctl >/dev/null 2>&1; then
  while IFS= read -r line; do
    (( count >= 8 )) && break
    mac=$(awk '{print $2}' <<< "$line")
    [[ -z "$mac" ]] && continue
    [[ ! "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] && continue
    h=$(printf '%s' "$mac" | md5sum)
    dist=$(( 30 + 16#${h:4:4} % 26 ))
    state="paired"
    read -r x y <<< "$(coords "$mac" "$dist")"
    DEVICES+=("$x $y bt $state")
    (( count++ ))
  done < <(timeout 2 bluetoothctl devices 2>/dev/null)
fi

# --- sweep line endpoint ---
angle=$(( ($(date +%s) * 4) % 360 ))
read -r sx sy <<< "$(awk -v a="$angle" -v c=76 -v r=72 'BEGIN {
  pi = 3.14159265358979
  rad = a * pi / 180
  print int(c + r * sin(rad) + 0.5), int(c - r * cos(rad) + 0.5)
}')"

# --- build magick draw sequence as array ---
CMD=(
  magick -size 152x152 xc:black

  # crosshairs
  -stroke '#0a0000' -strokewidth 2
  -draw "line 0,75 151,75"
  -draw "line 75,0 75,151"

  # concentric rings (r=19, 38, 57, 74)
  -fill none -stroke '#1c0000' -strokewidth 1
  -draw "circle 76,76 76,57"
  -draw "circle 76,76 76,38"
  -draw "circle 76,76 76,19"
  -stroke '#250000' -draw "circle 76,76 76,2"

  # sweep line from center to edge
  -stroke '#550000' -strokewidth 1
  -draw "line 76,76 ${sx},${sy}"
)

# device dots
for dev in "${DEVICES[@]}"; do
  read -r dx dy dproto dstate <<< "$dev"
  case "${dproto}:${dstate}" in
    arp:reachable|arp:delay|arp:probe) color='#ff0000' ;;
    arp:stale)                         color='#3a0000' ;;
    arp:*)                             color='#cc0000' ;;
    bt:connected)                      color='#cc3300' ;;
    bt:*)                              color='#772200' ;;
    *)                                 color='#330000' ;;
  esac
  # dot radius 4, drawn as filled circle
  ex=$(( dx + 4 ))
  CMD+=(-fill "$color" -stroke none -draw "circle ${dx},${dy} ${ex},${dy}")
done

# center origin dot (bright, on top of everything)
CMD+=(-fill '#ff0000' -stroke none -draw "circle 76,76 80,76")

CMD+=(-depth 8 "$OUT")

"${CMD[@]}" 2>/dev/null
echo "$OUT"
