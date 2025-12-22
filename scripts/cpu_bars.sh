#!/bin/bash
# Generate ASCII bar visualization for CPU cores

# Get per-core CPU usage
mpstat -P ALL 1 1 2>/dev/null | grep -A 100 "Average:" | tail -n +2 | grep -v "Average" | awk '{print int($3)}' | head -n 8 | while read usage; do
    bars=$((usage / 10))
    printf "["
    for i in $(seq 1 10); do
        if [ $i -le $bars ]; then
            printf "█"
        else
            printf "░"
        fi
    done
    printf "] %3d%%\n" "$usage"
done
