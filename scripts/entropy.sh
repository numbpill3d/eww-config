#!/usr/bin/env bash
# entropy.sh — reads kernel entropy pool, outputs bar + value
# e.g.  [##############......] 2867

ENT=$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo 0)
python3 -c "
e = $ENT
f = min(int(e * 20 / 4096), 20)
bar = '#' * f + '.' * (20 - f)
print(f'[{bar}] {e}')
"
