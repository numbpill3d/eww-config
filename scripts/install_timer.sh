#!/bin/bash
mkdir -p ~/.config/systemd/user/
cat > ~/.config/systemd/user/eww-device-scanner.timer << 'TIMEREOF'
[Unit]
Description=EWW Device Scanner Timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=30s
Persistent=true

[Install]
WantedBy=timers.target
TIMEREOF

cat > ~/.config/systemd/user/eww-device-scanner.service << 'SERVICEEOF'
[Unit]
Description=EWW Device Scanner

[Service]
Type=oneshot
ExecStart=%h/.config/eww/scripts/device_scanner.sh
Environment="DISPLAY=:0"
Environment="XAUTHORITY=%h/.Xauthority"
SERVICEEOF

systemctl --user daemon-reload
systemctl --user enable eww-device-scanner.timer
systemctl --user start eww-device-scanner.timer
