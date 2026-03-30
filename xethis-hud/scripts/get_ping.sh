#!/bin/bash
# ping gateway or 8.8.8.8 once, return ms
host=${1:-8.8.8.8}
res=$(ping -c1 -W1 "$host" 2>/dev/null | awk -F'/' 'END{print $5}')
if [[ -z "$res" ]]; then
  echo 999
else
  printf "%.0f" "$res"
fi
