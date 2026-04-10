#!/usr/bin/env bash
# entropy_wave.sh — animated noise pattern seeded from entropy level + urandom
# polled at 300ms so chars change each frame, denser/noisier as entropy rises

ENT=$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo 0)
python3 -c "
import random, os
e = $ENT
# always at least 2 char types; more variety as entropy rises toward 4096
# sparse chars first so low entropy = calm, high entropy = chaotic
tier = max(2, int(e / 4096 * 8) + 2)
all_chars = ['.', ':', '.', '|', ':', 'I', '|', ':']
chars = all_chars[:tier]
seed = int.from_bytes(os.urandom(4), 'little')
random.seed(seed)
wave = ''.join(random.choice(chars) for _ in range(30))
print(wave)
"
