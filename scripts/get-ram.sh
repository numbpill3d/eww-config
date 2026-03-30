#!bin/bash

free -m | awk '/Mem:/ {printf("%.0f%\n", $3/$2*100)}'