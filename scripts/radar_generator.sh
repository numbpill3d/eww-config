#!/bin/bash
echo '{
  "sweep_angle": '$(( $(date +%s) * 10 % 360 ))',
  "dots": [
    {"x": 80, "y": 120, "mac": "aa:bb:cc:dd:ee:ff"},
    {"x": 130, "y": 90, "mac": "11:22:33:44:55:66"},
    {"x": 70, "y": 70, "mac": "ff:ee:dd:cc:bb:aa"}
  ]
}'
