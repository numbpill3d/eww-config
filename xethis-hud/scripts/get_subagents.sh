#!/bin/bash
# counts active subagents directory entries
if [[ -d "$HOME/.openclaw/subagents" ]]; then
  count=$(ls -1 "$HOME/.openclaw/subagents" | wc -l)
  echo $count
else
  echo 0
fi
