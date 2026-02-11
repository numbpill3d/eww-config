#!/bin/bash
# ThinkPad L15 Thermal Safety Setup
# Ensures thermald, thinkfan, and CPU governor run automatically

echo "Updating system..."
sudo pacman -Syu --noconfirm

# --- 1. Install necessary packages ---
echo "Installing thinkfan, cpupower, and lm_sensors..."
sudo pacman -S --noconfirm thinkfan cpupower lm_sensors

# Optional: install monitoring tools
# sudo pacman -S --noconfirm s-tui powertop tlp

# --- 2. Configure thinkfan ---
echo "Setting up thinkfan configuration..."
sudo tee /etc/thinkfan.conf > /dev/null << 'CONF_EOF'
# ThinkFan config for ThinkPad L15 i5-1135G7
hwmon0/pwm1 0 50
hwmon0/pwm1 1 60
hwmon0/pwm1 2 70
hwmon0/pwm1 3 80
hwmon0/pwm1 4 85
hwmon0/pwm1 5 100

hwmon0/temp1_input
hwmon0/temp2_input
hwmon0/temp3_input
hwmon0/temp4_input
hwmon0/temp5_input

interval 2
CONF_EOF

echo "Enabling thinkfan..."
sudo systemctl enable --now thinkfan

# --- 3. Configure thermald ---
echo "Patching thermald service to ignore CPUID check..."
sudo systemctl stop thermald
sudo systemctl edit --full thermald << 'THRM_EOF'
[Unit]
Description=Thermal Daemon Service
ConditionVirtualization=no

[Service]
Type=dbus
SuccessExitStatus=2
BusName=org.freedesktop.thermald
ExecStart=/usr/bin/thermald --systemd --dbus-enable --adaptive --ignore-cpuid-check
Restart=on-failure

[Install]
WantedBy=multi-user.target
Alias=dbus-org.freedesktop.thermald.service
THRM_EOF

sudo systemctl daemon-reexec
sudo systemctl enable --now thermald

# --- 4. Set CPU governor to powersave ---
echo "Setting CPU governor to powersave..."
sudo cpupower frequency-set -g powersave

# Make it persistent at boot
echo 'GOVERNOR="powersave"' | sudo tee /etc/default/cpupower

# --- 5. Sensors detection ---
echo "Detecting hardware sensors..."
sudo sensors-detect --auto

# --- 6. Done ---
echo "Setup complete. Check temps with:"
echo "  watch -n 2 sensors"
echo "Monitor CPU usage with:"
echo "  htop"
echo "Thinkfan and thermald are running."
