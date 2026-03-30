#!/usr/bin/env bash
# agent_matrix.sh — animated ascii waterfall for home view
# sized to fill 260x260 window minus topbar (~26px) and homebar (~38px)
# at 10px Terminus: ~6px/char wide, ~12px/char tall → 42 cols, 16 rows

ROWS=16
COLS=42
CHARS='01_-.:|/[]{}()~^+*#@!;><='

for ((r=0; r<ROWS; r++)); do
  line=""
  # top third: dense. bottom third: sparse. gives waterfall depth.
  if   (( r < ROWS/3 ));     then blank_odds=0
  elif (( r < 2*ROWS/3 ));   then blank_odds=3
  else                             blank_odds=6
  fi
  for ((c=0; c<COLS; c++)); do
    if (( blank_odds > 0 && RANDOM % 10 < blank_odds )); then
      line+=" "
    else
      line+="${CHARS:$((RANDOM % ${#CHARS})):1}"
    fi
  done
  echo "$line"
done
