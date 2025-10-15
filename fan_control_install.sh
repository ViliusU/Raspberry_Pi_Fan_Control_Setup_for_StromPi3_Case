#!/bin/bash

# Update and upgrade the system using both apt and apt-get
echo "Updating and upgrading the system using apt..."
sudo apt update && sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "Updating and upgrading the system using apt-get..."
sudo apt-get update && sudo apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Install necessary dependencies
echo "Installing necessary packages..."
sudo apt install -y python3-full
sudo apt-get install -y python3-gpiozero python3-rpi.gpio

# Create the fan_control.py script
echo "Creating fan_control.py script..."
cat << 'EOF' | sudo tee /home/menulis/fan_control.py > /dev/null
from gpiozero import CPUTemperature, PWMLED
from time import sleep

led = PWMLED(2)  # PWM-Pin (GPIO2)

startTemp = 50  # Temperature at which the fan switches on

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

# Create /etc/rc.local if it doesn't exist
echo "Creating /etc/rc.local..."
cat << 'EOF' | sudo tee /etc/rc.local > /dev/null
#!/bin/bash
# rc.local startup script

python3 /home/menulis/fan_control.py &

exit 0
EOF

# Make rc.local executable
echo "Making /etc/rc.local executable..."
sudo chmod +x /etc/rc.local

# Create the rc-local.service if not present
echo "Creating rc-local.service..."
cat << 'EOF' | sudo tee /etc/systemd/system/rc-local.service > /dev/null
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

# Reload and enable the service
echo "Enabling rc-local.service..."
sudo systemctl daemon-reload
sudo systemctl enable rc-local.service
sudo systemctl start rc-local.service

# Show service status
echo "Checking rc-local.service status..."
sudo systemctl status rc-local.service

# Reboot the system
echo "Rebooting the system..."
sudo reboot
