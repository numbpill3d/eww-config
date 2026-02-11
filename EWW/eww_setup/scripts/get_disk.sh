#!/bin/bash
# Disk usage monitoring script

disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
echo "$disk_usage"
