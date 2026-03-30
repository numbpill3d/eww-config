#!/bin/bash
# Returns Memory usage percentage 0-100
free | awk '/Mem:/ {printf "%d", ($3/$2)*100}'
