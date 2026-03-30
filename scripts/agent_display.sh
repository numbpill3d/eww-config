#!/usr/bin/env bash
# agent_display.sh — outputs exactly ROWS lines
# reads conversation history or shows matrix animation when empty

ROWS=60
COLS=60
CHARS='01_-.:|/[]{}()~^+*#@!;'

content=$(cat /tmp/eww_agent_conv 2>/dev/null \
  | sed 's/\x1b\[[0-9;]*[mGKHF]//g; s/\x1b\[[?][0-9]*[hl]//g; s/\r//g' \
  | tr -d '\000-\010\013\014\016-\031' \
  | tr -d '⠀⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟⠠⠡⠢⠣⠤⠥⠦⠧⠨⠩⠪⠫⠬⠭⠮⠯⠰⠱⠲⠳⠴⠵⠶⠷⠸⠹⠺⠻⠼⠽⠾⠿')

if [[ -n "$content" ]]; then
  mapfile -t lines < <(printf '%s' "$content" | tail -n $ROWS)
  for line in "${lines[@]}"; do echo "$line"; done
  remaining=$(( ROWS - ${#lines[@]} ))
  for ((i=0; i<remaining; i++)); do echo ""; done
else
  # matrix waterfall — denser at top, sparse toward bottom
  for ((r=0; r<ROWS; r++)); do
    line=""
    blank_odds=$(( r * 9 / ROWS ))
    for ((c=0; c<COLS; c++)); do
      if (( blank_odds > 0 && RANDOM % 10 < blank_odds )); then
        line+=" "
      else
        line+="${CHARS:$((RANDOM % ${#CHARS})):1}"
      fi
    done
    echo "$line"
  done
fi
