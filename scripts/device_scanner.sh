#!/bin/bash
DATA_DIR="$HOME/.config/eww/data"
KNOWN_DEVICES="$DATA_DIR/known_devices"
SEEN_CACHE="$DATA_DIR/seen_cache"
NOTIFIED="$DATA_DIR/notified"

mkdir -p "$DATA_DIR"
touch "$KNOWN_DEVICES" "$SEEN_CACHE" "$NOTIFIED"

declare -A current_devices
declare -A device_labels

# Load known labels
while IFS='=' read -r mac label; do
  [[ -n "$mac" ]] && device_labels["$mac"]="$label"
done < "$KNOWN_DEVICES"

# Collect ARP entries
while read -r ip _ _ mac _; do
  [[ -z "$mac" || "$mac" == "incomplete" ]] && continue
  current_devices["$mac"]="$ip|arp|"
done < <(ip neigh show 2>/dev/null)

# Collect WiFi via iw (requires sudo)
if command -v iw >/dev/null 2>&1; then
  for iface in $(iw dev 2>/dev/null | grep Interface | awk '{print $2}'); do
    while read -r line; do
      if [[ "$line" =~ ([0-9a-fA-F:]{17}) ]]; then
        mac="${BASH_REMATCH[1]}"
        current_devices["$mac"]="|wifi|$iface"
      fi
    done < <(sudo iw dev "$iface" scan 2>/dev/null | grep "^BSS")
  done
fi

# Collect Bluetooth
if command -v bluetoothctl >/dev/null 2>&1; then
  while read -r _ mac name; do
    [[ -n "$mac" ]] && current_devices["$mac"]="|bluetooth|$name"
  done < <(bluetoothctl devices 2>/dev/null)
fi

# Output for EWW
echo -n "["
first=true
for mac in "${!current_devices[@]}"; do
  details="${current_devices[$mac]}"
  ip=$(echo "$details" | cut -d'|' -f1)
  type=$(echo "$details" | cut -d'|' -f2)
  extra=$(echo "$details" | cut -d'|' -f3)
  
  # Update seen cache
  grep -q "^$mac$" "$SEEN_CACHE" 2>/dev/null || echo "$mac" >> "$SEEN_CACHE"
  
  # Determine category
  label="${device_labels[$mac]}"
  category="unknown"
  [[ -n "$label" ]] && category="known"
  [[ "$label" == "ENEMY" ]] && category="enemy"
  
  # Send notification for new devices
  if ! grep -q "^$mac$" "$NOTIFIED" 2>/dev/null; then
    notify-send -u low "Device Detected" "MAC: $mac\nIP: $ip\nType: $type" 2>/dev/null || true
    echo "$mac" >> "$NOTIFIED"
  fi
  
  if [[ "$first" == true ]]; then
    first=false
  else
    echo -n ","
  fi
  
  echo -n "{\"mac\": \"$mac\", \"ip\": \"$ip\", \"type\": \"$type\", \"label\": \"$label\", \"category\": \"$category\"}"
done
echo "]"
