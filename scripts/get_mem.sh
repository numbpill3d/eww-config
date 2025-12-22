#!/bin/bash
# Memory usage monitoring script

mem_usage=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
printf "%.0f" "$mem_usage"
