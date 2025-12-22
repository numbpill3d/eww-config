#!/bin/bash
cpu=$(sensors | awk '/Package id 0:/ {print int($4)}')
mem=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
if (( cpu > 85 || mem > 90 )); then
  eww update moodface="(>_<)"
elif (( cpu > 70 || mem > 75 )); then
  eww update moodface="(o_o)"
elif (( cpu > 50 || mem > 60 )); then
  eww update moodface="(-_-)"
else
  eww update moodface="(^_^)"
fi
