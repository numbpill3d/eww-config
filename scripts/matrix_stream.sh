#!/bin/bash
# Matrix streaming code effect

streams=(
  "01001000 01000001 01000011"
  "0xDEAD 0xBEEF 0xCAFE"
  ">>> BREACH DETECTED <<<"
  "|| FIREWALL ACTIVE ||"
  ">> ACCESS GRANTED <<"
  "01010011 59 53 54 45"
  "0xFF0000 CRITICAL"
  ">>> MONITORING <<<"
  "|| ENCRYPTION ON ||"
  "01000101 4E 43 52"
)

echo "${streams[$RANDOM % ${#streams[@]}]}"
