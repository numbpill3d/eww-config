#!/usr/bin/env bash
# rf_live.sh — live nearby device scan (arp + bluetooth)
# stdout:  JSON array [{addr,mac,key,proto,state,state_s,sig,display,vendor,new,x,y,oui}]
# side fx: writes /tmp/eww_rf_summary  (e.g. "a:3  b:1  !2")
# NOTE: key=IP for ARP (proxy-ARP networks share one MAC), key=MAC for BT

RADAR_C=76
KNOWN_FILE="$HOME/.config/eww/data/known_devices"
NICK_FILE="$HOME/.config/eww/data/device_nicknames"
mkdir -p "$(dirname "$KNOWN_FILE")"
touch "$KNOWN_FILE"
touch "$NICK_FILE" 2>/dev/null

# --- Active subnet sweep ---
# ip neigh is passive; without this, only the gateway shows up.
# nmap -sn sends ICMP/ARP probes to every host on the local subnet,
# which populates the kernel ARP table so ip neigh sees them.
# Run in background so this poll returns quickly; results appear next cycle.
_subnet=$(ip route 2>/dev/null \
  | awk '/proto kernel/ && !/169\.254/ && !/linkdown/ {print $1; exit}')
if [[ -n "$_subnet" ]]; then
  nmap -sn -T5 --host-timeout 200ms --max-retries 0 "$_subnet" \
    &>/dev/null &
  disown $!
fi

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

oui_vendor() {
  local mac="$1"
  local oui_plain
  oui_plain=$(printf '%s' "$mac" | tr -d ':' | cut -c1-6 | tr '[:lower:]' '[:upper:]')
  local vendor=""
  if [[ -f /usr/share/nmap/nmap-mac-prefixes ]]; then
    vendor=$(awk -v o="$oui_plain" \
      'toupper($1)==o{$1=""; sub(/^ /,""); print; exit}' \
      /usr/share/nmap/nmap-mac-prefixes 2>/dev/null | cut -c1-9)
  fi
  echo "${vendor:-${mac:0:8}}"
}

get_hostname() {
  local ip="$1"
  local hn
  hn=$(timeout 0.4 getent hosts "$ip" 2>/dev/null \
    | awk '{print $2}' | sed 's/\..*//' | cut -c1-14)
  echo "${hn:-}"
}

jesc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

short_state() {
  case "$1" in
    reachable|delay|probe) echo "up"    ;;
    stale)                 echo "stale" ;;
    connected)             echo "conn"  ;;
    paired)                echo "pair"  ;;
    *)                     printf '%s' "$1" | cut -c1-5 ;;
  esac
}

guess_type() {
  local ip="$1" vendor="$2" hn="$3"
  local v="${vendor,,}" h="${hn,,}"
  local last
  last=$(printf '%s' "$ip" | awk -F. '{print $4+0}')
  [[ "$last" -eq 1 || "$last" -eq 254 ]] && echo "rtr" && return
  [[ "$h" =~ router|gateway|gw|modem|access.?point ]] && echo "rtr" && return
  [[ "$v" =~ cisco|netgear|tp-link|tplink|d-link|linksys|asus|mikrotik|ubiquiti|aruba|edgerouter|fortinet|zyxel ]] && echo "rtr" && return
  [[ "$v" =~ apple|samsung|huawei|xiaomi|oneplus|oppo|motorola|sony.*mobile|lg.*electr|realme|vivo|nokia ]] && echo "phn" && return
  [[ "$v" =~ intel|dell|lenovo|"hp inc"|acer|toshiba|quanta|compal|hp.*comp ]] && echo "lap" && return
  [[ "$v" =~ espressif|raspberry|arduino|microchip|stmicro|nordic|beagle ]] && echo "iot" && return
  [[ "$v" =~ sonos|roku|amazon|google|philips|hisense|sharp|vizio ]] && echo "tv"  && return
  echo "unk"
}

# 4-char signal bar: filled ▓ vs dim ░ based on state proximity
sig_bar() {
  case "$1" in
    reachable|connected) echo "▓▓▓▓" ;;
    delay)               echo "▓▓▓░" ;;
    probe|paired)        echo "▓▓░░" ;;
    stale)               echo "▓░░░" ;;
    *)                   echo "░░░░" ;;
  esac
}

result="["
sep=""
count=0
arp_count=0
bt_count=0
new_count=0

# --- ARP neighbors ---
while IFS= read -r line; do
  (( count >= 20 )) && break
  ip=$(awk '{print $1}' <<< "$line")
  mac=$(awk '{for(i=1;i<=NF;i++) if($i=="lladdr"){print $(i+1); exit}}' <<< "$line")
  state=$(awk '{print $NF}' <<< "$line")

  [[ -z "$mac" ]] && continue
  [[ "$mac" == "ff:ff:ff:ff:ff:ff" ]] && continue
  [[ ! "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] && continue

  # Use IP as unique key — on proxy-ARP networks every device shares the
  # router's MAC, so MAC-based deduplication and known/new tracking breaks.
  # IP uniquely identifies each host regardless of MAC aliasing.
  h=$(printf '%s' "$ip" | md5sum)
  base=$(( 16#${h:4:4} % 18 ))
  case "$state" in
    REACHABLE|DELAY|PROBE) dist=$(( 15 + base )) ;;
    STALE)                 dist=$(( 45 + base )) ;;
    *)                     dist=$(( 32 + base )) ;;
  esac

  read -r x y <<< "$(coords "$ip" "$dist")"
  state_l="${state,,}"
  state_s=$(short_state "$state_l")
  sig=$(sig_bar "$state_l")
  last_oct=$(printf '%s' "$ip" | awk -F. '{print "."$4}')
  hostname=$(get_hostname "$ip")
  vendor=$(oui_vendor "$mac")
  dtype=$(guess_type "$ip" "$vendor" "$hostname")
  display="${hostname:-$ip}"
  nick=$(awk -v k="$ip" '$1==k{print $2; exit}' "$NICK_FILE" 2>/dev/null)
  [[ -n "$nick" ]] && display="$nick"
  is_new="false"
  grep -qF "$ip" "$KNOWN_FILE" 2>/dev/null || { is_new="true"; (( new_count++ )); }

  result+="${sep}{\"addr\":\"$(jesc "$ip")\",\"mac\":\"$(jesc "$mac")\",\"key\":\"$(jesc "$ip")\",\"proto\":\"arp\",\"state\":\"$(jesc "$state_l")\",\"state_s\":\"$(jesc "$state_s")\",\"sig\":\"$(jesc "$sig")\",\"display\":\"$(jesc "$display")\",\"vendor\":\"$(jesc "$vendor")\",\"dtype\":\"$dtype\",\"new\":\"$is_new\",\"x\":$x,\"y\":$y,\"oui\":\"$(jesc "$last_oct")\"}"
  sep=","
  (( count++ ))
  (( arp_count++ ))
done < <(ip neigh show 2>/dev/null | grep -E 'REACHABLE|STALE|DELAY|PROBE')

# --- Bluetooth ---
if command -v bluetoothctl >/dev/null 2>&1; then
  while IFS= read -r line; do
    (( count >= 20 )) && break
    mac=$(awk '{print $2}' <<< "$line")
    name=$(cut -d' ' -f3- <<< "$line" | tr -d '"\\')
    [[ -z "$mac" ]] && continue
    [[ ! "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] && continue
    [[ -z "$name" || "$name" == "$mac" ]] && name="${mac:0:8}"

    h=$(printf '%s' "$mac" | md5sum)
    dist=$(( 30 + 16#${h:4:4} % 26 ))

    bt_info=$(timeout 0.5 bluetoothctl info "$mac" 2>/dev/null)
    state="paired"
    printf '%s' "$bt_info" | grep -q "Connected: yes" && state="connected"
    bt_icon=$(printf '%s' "$bt_info" | awk '/Icon:/{print $2; exit}')
    case "$bt_icon" in
      phone)                                    dtype="phn" ;;
      computer)                                 dtype="lap" ;;
      audio-card|headphones|headset|audio-headset) dtype="spk" ;;
      input-keyboard|input-mouse|input-gaming)  dtype="kbd" ;;
      *)                                        dtype="unk" ;;
    esac
    state_s=$(short_state "$state")
    sig=$(sig_bar "$state")

    read -r x y <<< "$(coords "$mac" "$dist")"
    oui="${mac:0:8}"
    vendor=$(oui_vendor "$mac")
    display="$name"
    nick=$(awk -v k="$mac" '$1==k{print $2; exit}' "$NICK_FILE" 2>/dev/null)
    [[ -n "$nick" ]] && display="$nick"
    is_new="false"
    grep -qF "$mac" "$KNOWN_FILE" 2>/dev/null || { is_new="true"; (( new_count++ )); }

    result+="${sep}{\"addr\":\"$(jesc "$name")\",\"mac\":\"$(jesc "$mac")\",\"key\":\"$(jesc "$mac")\",\"proto\":\"bt\",\"state\":\"$(jesc "$state")\",\"state_s\":\"$(jesc "$state_s")\",\"sig\":\"$(jesc "$sig")\",\"display\":\"$(jesc "$display")\",\"vendor\":\"$(jesc "$vendor")\",\"dtype\":\"$dtype\",\"new\":\"$is_new\",\"x\":$x,\"y\":$y,\"oui\":\"$(jesc "$oui")\"}"
    sep=","
    (( count++ ))
    (( bt_count++ ))
  done < <(timeout 2 bluetoothctl devices 2>/dev/null)
fi

# write summary side-file for the header label
summary="a:${arp_count}  b:${bt_count}"
(( new_count > 0 )) && summary+="  !${new_count}"
echo "$summary" > /tmp/eww_rf_summary

json_out="${result}]"
echo "$json_out"
echo "$json_out" > /tmp/eww_rf_devices.json
