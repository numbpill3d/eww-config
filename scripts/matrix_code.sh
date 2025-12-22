#!/bin/bash
# Matrix code generator - returns random hex/binary for display

# Array of hacker-style strings
codes=(
  "0x4E45544D4154524958"
  "0xDEADBEEF"
  "0x41434345535300"
  "01010011 01011001 01010011"
  "0xFF0000"
  ">> ACCESS GRANTED <<"
  ">> SCANNING PORTS <<"
  ">> BREACH DETECTED <<"
  "0xC0FFEE"
  "0x1337C0DE"
)

# Pick random code
echo "${codes[$RANDOM % ${#codes[@]}]}"
