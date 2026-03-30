#!/usr/bin/env bash
# scan_focus.sh <proto> <key>
# proto: wifi | arp | bt
# writes formatted detail to /tmp/eww_scan_focus for the scan panel focus widget

PROTO="$1"
KEY="$2"
FOCUS=/tmp/eww_scan_focus

OUI_DB=/usr/share/nmap/nmap-mac-prefixes

vendor_lookup() {
    local mac="$1"
    local oui
    oui=$(printf '%s' "$mac" | tr -d ':' | cut -c1-6 | tr '[:lower:]' '[:upper:]')
    if [[ -f "$OUI_DB" ]]; then
        awk -v o="$oui" 'toupper($1)==o{$1=""; sub(/^ /,""); print; exit}' "$OUI_DB" | cut -c1-32
    fi
}

{
case "$PROTO" in
  wifi)
    r=$(nmcli -g SSID,BSSID,SIGNAL,SECURITY,CHAN device wifi list bssid "$KEY" 2>/dev/null \
        | head -1)
    if [[ -n "$r" ]]; then
        ssid=$(  printf '%s' "$r" | python3 -c "import sys,re; p=re.split(r'(?<!\\\\):', sys.stdin.read().rstrip()); print(p[0].replace('\\\\:',':').strip() if len(p)>0 else '')")
        sig=$(   printf '%s' "$r" | python3 -c "import sys,re; p=re.split(r'(?<!\\\\):', sys.stdin.read().rstrip()); print(p[2].strip() if len(p)>2 else '')")
        sec=$(   printf '%s' "$r" | python3 -c "import sys,re; p=re.split(r'(?<!\\\\):', sys.stdin.read().rstrip()); print(p[3].strip() if len(p)>3 else '')")
        chan=$(   printf '%s' "$r" | python3 -c "import sys,re; p=re.split(r'(?<!\\\\):', sys.stdin.read().rstrip()); print(p[4].strip() if len(p)>4 else '')")
        [[ -z "$sec" ]] && sec="OPEN"
        dbm="?"; [[ "$sig" =~ ^[0-9]+$ ]] && dbm=$(( sig / 2 - 100 ))
        band="2.4G"; [[ -n "$chan" ]] && (( chan >= 36 )) 2>/dev/null && band="5G"
        vendor=$(vendor_lookup "$KEY")
    else
        ssid="[not found]"; sig="?"; sec="?"; chan="?"; dbm="?"; band="?"; vendor=""
    fi
    printf '[ WIFI ]\n'
    printf 'ssid    %s\n'           "$ssid"
    printf 'bssid   %s\n'           "$KEY"
    printf 'signal  %s%%  (%sdBm)\n' "$sig" "$dbm"
    printf 'chan    ch%s  %s\n'     "$chan" "$band"
    printf 'sec     %s\n'           "$sec"
    [[ -n "$vendor" ]] && printf 'vendor  %s\n' "$vendor"
    true
    ;;

  arp)
    ip="$KEY"
    line=$(ip neigh show "$ip" 2>/dev/null | head -1)
    mac=$(awk '{for(i=1;i<=NF;i++) if($i=="lladdr"){print $(i+1); exit}}' <<< "$line")
    state=$(awk '{print $NF}' <<< "$line" | tr '[:upper:]' '[:lower:]')
    host=$(timeout 0.4 getent hosts "$ip" 2>/dev/null | awk '{print $2}' | head -1)
    vendor=$(vendor_lookup "$mac")
    printf '[ ARP ]\n'
    printf 'ip      %s\n'  "$ip"
    [[ -n "$mac"    ]] && printf 'mac     %s\n'  "$mac"
    [[ -n "$host"   ]] && printf 'host    %s\n'  "$host"
    [[ -n "$state"  ]] && printf 'state   %s\n'  "$state"
    [[ -n "$vendor" ]] && printf 'vendor  %s\n'  "$vendor"
    true
    ;;

  bt)
    mac="$KEY"
    info=$(timeout 1 bluetoothctl info "$mac" 2>/dev/null)
    name=$(  awk '/^\s+Name:/{sub(/.*Name: /,""); print}' <<< "$info")
    alias=$( awk '/^\s+Alias:/{sub(/.*Alias: /,""); print}' <<< "$info")
    icon=$(  awk '/^\s+Icon:/{sub(/.*Icon: /,""); print}' <<< "$info")
    conn=$(  awk '/^\s+Connected:/{print $2}' <<< "$info")
    paired=$(awk '/^\s+Paired:/{print $2}' <<< "$info")
    trusted=$(awk '/^\s+Trusted:/{print $2}' <<< "$info")
    vendor=$(vendor_lookup "$mac")
    printf '[ BT ]\n'
    printf 'mac     %s\n'  "$mac"
    [[ -n "$name"    ]] && printf 'name    %s\n'  "$name"
    [[ -n "$alias"   && "$alias" != "$name" ]] && printf 'alias   %s\n' "$alias"
    [[ -n "$icon"    ]] && printf 'icon    %s\n'  "$icon"
    [[ -n "$conn"    ]] && printf 'conn    %s\n'  "$conn"
    [[ -n "$paired"  ]] && printf 'paired  %s\n'  "$paired"
    [[ -n "$trusted" ]] && printf 'trusted %s\n'  "$trusted"
    [[ -n "$vendor"  ]] && printf 'vendor  %s\n'  "$vendor"
    true
    ;;

  *)
    printf '[ click any row to inspect ]\n'
    ;;
esac
} > "$FOCUS"
