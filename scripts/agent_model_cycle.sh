#!/usr/bin/env bash
# agent_model_cycle.sh — cycle agent model through installed ollama models

CURRENT=$(cat /tmp/eww_agent_model 2>/dev/null | tr -d '[:space:]')

# build list from installed models; fall back to hardcoded if ollama unreachable
mapfile -t MODELS < <(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v '^$')
[[ ${#MODELS[@]} -eq 0 ]] && MODELS=("qwen2.5:3b")

[[ -z "$CURRENT" ]] && CURRENT="${MODELS[0]}"

IDX=0
for i in "${!MODELS[@]}"; do
  [[ "${MODELS[$i]}" == "$CURRENT" ]] && IDX=$i && break
done

NEXT=$(( (IDX + 1) % ${#MODELS[@]} ))
echo "${MODELS[$NEXT]}" > /tmp/eww_agent_model
