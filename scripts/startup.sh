#!/bin/bash
# EWW Cyberpunk Dashboard Startup

sleep 5
eww daemon
sleep 3

eww open marquee_bar
eww open cpu_widget
eww open mem_widget
eww open disk_widget
eww open net_widget
eww open sysinfo_widget
eww open activity_widget
eww open radar_widget
eww open code_rain_left
