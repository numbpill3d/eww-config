#!/usr/bin/env bash
# ping_daemon.sh — pings default gateway every 3s
# writes /tmp/eww_ping_ms (e.g. "14ms") and /tmp/eww_ping_spark (sparkline)
# started by autostart.sh

HIST_FILE="/tmp/eww_ping_hist"
MAX=20
SPARK="▁▂▃▄▅▆▇█"

get_gw() {
    ip route show default 2>/dev/null | awk '/default/ {print $3; exit}'
}

ms_to_char() {
    local ms=$1
    local idx=$(( ms * 7 / 150 ))
    [ "$idx" -gt 7 ] && idx=7
    printf '%s' "${SPARK:$idx:1}"
}

render() {
    local out=""
    for v in $1; do
        out+=$(ms_to_char "$v")
    done
    printf '%s' "$out"
}

touch "$HIST_FILE"

while true; do
    gw=$(get_gw)

    if [ -z "$gw" ]; then
        printf '?\n'   > /tmp/eww_ping_ms
        printf '········\n' > /tmp/eww_ping_spark
        sleep 3
        continue
    fi

    ms=$(ping -c 1 -W 2 "$gw" 2>/dev/null \
         | awk -F'/' '/^rtt/ { printf "%d", $5 }')

    [ -z "$ms" ] && ms=999

    # append to ring buffer and trim to MAX entries
    read -r -a vals < <(tr '\n' ' ' < "$HIST_FILE" 2>/dev/null; echo "$ms")
    while [ "${#vals[@]}" -gt "$MAX" ]; do
        vals=( "${vals[@]:1}" )
    done
    printf '%s\n' "${vals[@]}" > "$HIST_FILE"

    printf '%dms\n' "$ms"        > /tmp/eww_ping_ms
    render "${vals[*]}"          > /tmp/eww_ping_spark

    sleep 3
done
