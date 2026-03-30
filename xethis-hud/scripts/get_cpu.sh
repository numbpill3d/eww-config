#!/bin/bash
# Returns CPU usage (0-100)
idle=$(grep 'cpu ' /proc/stat | awk '{print $5}')
sleep 0.4
idle2=$(grep 'cpu ' /proc/stat | awk '{print $5}')
total1=$(grep 'cpu ' /proc/stat | awk '{sum=0; for (i=2;i<=NF;i++) sum+=$i; print sum}')
sleep 0.4
total2=$(grep 'cpu ' /proc/stat | awk '{sum=0; for (i=2;i<=NF;i++) sum+=$i; print sum}')
idle_diff=$((idle2 - idle))
total_diff=$((total2 - total1))
if [[ $total_diff -eq 0 ]]; then
  echo 0
else
  usage=$(( (1000*(total_diff - idle_diff)/total_diff +5)/10 ))
  echo $usage
fi
