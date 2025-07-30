#!/bin/bash

# Update and upgrade the system using both apt and apt-get
echo "Updating and upgrading the system using apt..."
sudo apt update && sudo apt upgrade -y

echo "Updating and upgrading the system using apt-get..."
sudo apt-get update && sudo apt-get upgrade -y

# Install necessary dependencies
echo "Installing necessary packages..."
sudo apt install -y python3-full
sudo apt-get install -y python3-gpiozero python3-rpi.gpio

# Create the fan_control.py script
echo "Creating fan_control.py script..."
cat << 'EOF' > /home/menulis/fan_control.py
from gpiozero import CPUTemperature, PWMLED
from time import sleep

led = PWMLED(2)  # PWM-Pin (GPIO2)

startTemp = 55  # Temperature at which the fan switches on

pTemp = 4  # Proportional part
iTemp = 0.2  # Integral part

fanSpeed = 0  # Fan speed
sum = 0  # variable for i part

while True:  # Control loop
    cpu = CPUTemperature()  # Reading the current temperature values
    actTemp = cpu.temperature  # Current temperature as float variable
    
    diff = actTemp - startTemp
    sum = sum + diff
    pDiff = diff * pTemp
    iDiff = sum * iTemp
    fanSpeed = pDiff + iDiff + 35
    
    if fanSpeed > 100:
        fanSpeed = 100
    elif fanSpeed < 35:
        fanSpeed = 0
    if sum > 100:
        sum = 100
    elif sum < -100:
        sum = -100

    # pwm output to fan
    led.value = fanSpeed / 100

    sleep(1)
EOF

# Set execution permissions for the script
echo "Setting execute permissions for fan_control.py..."
sudo chmod +x /home/menulis/fan_control.py

# Modify rc.local to run the script on boot
echo "Configuring rc.local to run the script on startup..."
sudo sed -i '$i \python3 /home/menulis/fan_control.py &' /etc/rc.local

# Ensure rc.local is executable
echo "Ensuring rc.local is executable..."
sudo chmod +x /etc/rc.local

# Enable and check the rc-local service
echo "Checking rc-local service..."
sudo systemctl enable rc-local.service
sudo systemctl status rc-local.service

# Reboot the system
echo "Rebooting the system..."
sudo reboot
