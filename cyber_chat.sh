#!/bin/bash

update_chat() {
  eww update chat_display="┌─ LOG ─────────────────────────────────────┐\n│ $(date '+%H:%M') | $1                              │\n└────────────────────────────────────────────┘"
}

test() {
  eww update prompt_text=">_ Processing..."
  update_chat "TEST: Cyberdeck diagnostics PASS"
  eww update ascii_face="  /_\\_/\n ( ^.^ )\n  > ^ <" mood_text="[HAPPY]"
  sleep 2
  eww update prompt_text=">_ READY" ascii_face="  /_\\_/\n ( o.o )\n  > ^ <" mood_text="[IDLE]"
}

send() {
  eww update prompt_text=">_ Transmitting..."
  update_chat "SEND: Neural packet dispatched"
  sleep 1.5
  update_chat "AI: Packet received. Standing by."
  eww update prompt_text=">_ OK"
}

clear() {
  eww update chat_display="┌─ SYSTEM ─────────────────────────────────┐\n│ Log cleared. Buffer wiped.                │\n└────────────────────────────────────────────┘" prompt_text=">_ CLEARED"
  sleep 2
  eww update chat_display="┌─ SYSTEM BOOT ──────────────────────────────┐\n│ Cyberdeck Neural Interface v2.1             │\n│ OpenRouter API: READY (add key in script)   │\n│ CLI: cyber_chat.sh send \"message\"          │\n└─────────────────────────────────────────────┘" prompt_text=">_"
}

mood() {
  moods=(
    "excited:  /_\\_/\n (°° ) \n  > ^ < | [EXCITED]"
    "thinking:  /_\\_/\n ( ·.·)\n  > ^ < | [THINKING]"
    "sleepy:   /_\\_/\n ( -.- )\n  > ^ < | [SLEEPY]"
    "angry:    /_\\_/\n ( >.< )\n  > ^ < | [ANGRY]"
  )
  rand=$((RANDOM % 4))
  IFS=$'\n' read -r art mood <<< "${moods[$rand]}"
  eww update ascii_face="$art" mood_text="$mood"
  sleep 3
  eww update ascii_face="  /_\\_/\n ( o.o )\n  > ^ <" mood_text="[IDLE]"
}

send_cli() {
  msg="${2:-Test CLI}"
  update_chat "CLI: $msg received"
  eww update prompt_text=">_ ACK"
}

case "$1" in test|send|clear|mood) $@ ;; send_cli) send_cli "$2" ;; *) echo "test|send|clear|mood|send_cli msg" ;; esac
