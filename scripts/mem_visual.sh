#!/bin/bash
# Visual memory breakdown

free -h | awk 'NR==2 {
    printf "TOTAL: %s\n", $2
    printf "USED:  %s\n", $3
    printf "FREE:  %s\n", $4
    printf "CACHE: %s\n", $6
}'
