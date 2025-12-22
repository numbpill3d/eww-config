#!/bin/bash
KNOWN="/tmp/radar_known"
touch "$KNOWN"

empty() { echo '{"count":0,"devices":[],"ts":"'$(date +%H:%M:%S)'"}'; exit 0; }

mapfile -t N < <(ip neigh show | grep -v FAILED | awk '{if($5!="" && $5!="INCOMPLETE")print $1"|"$5}' | head -20)
[ ${#N[@]} -eq 0 ] && empty

OUT=""
C=0
for e in "${N[@]}"; do
    IFS='|' read -r ip mac <<< "$e"
    [ -z "$mac" ] && continue
    
    if ! grep -qF "$mac" "$KNOWN" 2>/dev/null; then
        echo "$mac" >> "$KNOWN"
        notify-send -u critical "⚠ NEW DEVICE" "$ip\n$mac" &
    fi
    
    H=$(echo -n "$mac" | md5sum | cut -c1-8)
    A=$((16#${H:0:4} % 360))
    D=$((20 + 16#${H:4:4} % 50))
    
    case $((A/45)) in
        0) X=$((76+D*7/10)); Y=$((76-D*2/10));;
        1) X=$((76+D*5/10)); Y=$((76-D*5/10));;
        2) X=$((76+D*1/10)); Y=$((76-D*7/10));;
        3) X=$((76-D*5/10)); Y=$((76-D*5/10));;
        4) X=$((76-D*7/10)); Y=$((76+D*2/10));;
        5) X=$((76-D*5/10)); Y=$((76+D*5/10));;
        6) X=$((76+D*1/10)); Y=$((76+D*7/10));;
        7) X=$((76+D*5/10)); Y=$((76+D*5/10));;
    esac
    
    [ $C -gt 0 ] && OUT+=","
    OUT+="{\"ip\":\"$ip\",\"mac\":\"$mac\",\"x\":$X,\"y\":$Y}"
    ((C++))
done

echo "{\"count\":$C,\"devices\":[$OUT],\"ts\":\"$(date +%H:%M:%S)\"}"
