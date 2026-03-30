#!/usr/bin/env bash
# agent_run.sh — run selected agent, append to conversation log

TASK=$(eww get agent_input 2>/dev/null)

TASK="${TASK#\"}" ; TASK="${TASK%\"}"
TASK="${TASK#\'}" ; TASK="${TASK%\'}"

[[ -z "$TASK" ]] && exit 0

eww update agent_input="" 2>/dev/null

# ---- slash commands ----
case "$TASK" in
  /chat)
    eww close agent-chat 2>/dev/null; eww open agent-chat-view 2>/dev/null
    exit 0 ;;
  /agents)
    eww close agent-chat 2>/dev/null; eww open agent-agents 2>/dev/null
    exit 0 ;;
  /home)
    eww close agent-chat-view 2>/dev/null; eww close agent-agents 2>/dev/null
    eww open agent-chat 2>/dev/null
    exit 0 ;;
  /clear|/clr)
    printf '' > /tmp/eww_agent_conv
    exit 0 ;;
  /help)
    eww close agent-chat 2>/dev/null; eww open agent-chat-view 2>/dev/null
    { echo ""; echo "[help]"
      echo "  /chat      chat view"
      echo "  /agents    agent launcher"
      echo "  /home      back to home"
      echo "  /clr       clear conversation"
      echo "  /help      this message"
    } >> /tmp/eww_agent_conv
    exit 0 ;;
esac

# auto-switch from home to chat on non-slash input
eww close agent-chat 2>/dev/null
eww open agent-chat-view 2>/dev/null

MODEL=$(cat /tmp/eww_agent_model 2>/dev/null | tr -d '[:space:]')
[[ -z "$MODEL" ]] && MODEL="qwen2.5:3b"

# append user turn header
{ echo ""; echo "[you]  $TASK"; echo "[$MODEL]"; } >> /tmp/eww_agent_conv

echo "running" > /tmp/eww_agent_status

strip_ansi() {
  sed 's/\x1b\[[0-9;]*[mGKHF]//g; s/\x1b\[[?][0-9]*[hl]//g; s/\r//g'
}

ollama run "$MODEL" "$TASK" 2>/dev/null \
  | strip_ansi | fold -s -w 58 >> /tmp/eww_agent_conv

echo "" >> /tmp/eww_agent_conv
echo "idle" > /tmp/eww_agent_status

# refocus the chat window input so user can type immediately
ydotool mousemove --absolute -x 960 -y 705 2>/dev/null
sleep 0.05
ydotool click 0xC0 2>/dev/null
