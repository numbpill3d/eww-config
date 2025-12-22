#!/bin/bash
# Disk I/O activity

iostat -d 1 2 2>/dev/null | tail -n +4 | grep -v "^$" | tail -1 | awk '{printf "R: %.1fMB/s\nW: %.1fMB/s", $3, $4}'
