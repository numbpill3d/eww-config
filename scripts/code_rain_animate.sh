#!/bin/bash

# Configuration
ROWS=8
lines=(" " " " " " " " " " " " " " " ")

get_hex() {
    # Mixes system data with randomness for that "hacker" look
    case $((RANDOM % 5)) in
        0) printf "0x%X" $(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo $RANDOM) ;;
        1) printf "0x%X" $(ps aux | wc -l) ;;
        2) printf "0x%s" $(head /dev/urandom | tr -dc 'A-F0-9' | head -c 4) ;;
        3) printf "0x%X" $(( $(date +%N) / 1000000 )) ;;
        4) printf "0x%X" $(free | awk '/Mem:/ {print $3 % 10000}') ;;
    esac
}

while true; do
    # Shift array: move everything down and add a new hex at the top
    new_val=$(get_hex)
    lines=("$new_val" "${lines[@]:0:$((ROWS-1))}")

    # Join array with newline characters for Eww to parse
    printf "%s\n" "${lines[@]}"
    
    # Speed of animation (0.1 is smooth, 0.2 is more readable)
    sleep 0.15
done
