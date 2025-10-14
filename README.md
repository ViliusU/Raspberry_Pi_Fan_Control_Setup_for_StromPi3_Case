# Raspberry Pi Fan Control Setup for StromPi3 Case

This script is designed to control the fan in the **STROMPI3 JOY-IT** Raspberry Pi case, which is equipped with a temperature sensor. The fan speed is adjusted based on the CPU temperature of the Raspberry Pi. The script will automatically run on startup, ensuring the fan adjusts its speed according to the temperature without needing manual intervention.

For more details on the STROMPI3 case, visit the [vendor page](https://joy-it.net/en/products/RB-StromPi3-Case) and check the original [datasheet](link-to-datasheet).

## Features:
- **Automatic Fan Control**: The fan speed is dynamically adjusted based on CPU temperature.
- **Startup Integration**: The script runs automatically at boot by modifying the `rc.local` configuration.
- **Proportional-Integral Control**: A basic PID (Proportional-Integral-Derivative) algorithm is used to control the fan speed.

## Hardware Requirements:
- **Raspberry Pi** (any model that supports GPIO, tested on Raspberry Pi 4).
- **STROMPI3 JOY-IT Raspberry Pi Case** with a temperature sensor and PWM-controlled fan.

### Vendor Product Link:
- [STROMPI3 JOY-IT Case](https://joy-it.net/en/products/RB-StromPi3-Case)

### Datasheet:
- [STROMPI3 JOY-IT Datasheet](link-to-datasheet)

## Software Requirements:
- Raspberry Pi OS installed on your Raspberry Pi.
- Python 3 and necessary libraries (`gpiozero`, `RPi.GPIO`) installed.

## Setup Instructions:

### 1. **Download and Prepare the Installer Script**
Clone this repository and navigate into it:

```bash
git clone <repository-url>
cd <repository-directory>
```

Make the installer script executable:

```bash
chmod +x fan_control_install.sh
```

### 2. **Run the Installer Script**
Execute the installer script to set up everything automatically:

```bash
./fan_control_install.sh
```

This will:
- Update and upgrade the system (using both apt and apt-get with force-conf options).
- Install Python 3, `gpiozero`, and `RPi.GPIO`.
- Create and configure `fan_control.py`.
- Set up `rc.local` and `rc-local.service` for automatic startup.
- Reboot the system.

### 3. **Manual Alternative Setup**
(If you prefer manual steps, follow these commands:)

#### **Update and Upgrade the System**
```bash
sudo apt update && sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
sudo apt-get update && sudo apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
```

#### **Install Required Packages**
```bash
sudo apt install -y python3-full
sudo apt-get install -y python3-gpiozero python3-rpi.gpio
```

#### **Create the Fan Control Script**
```bash
sudo tee /home/menulis/fan_control.py << 'EOF'
from gpiozero import CPUTemperature, PWMLED
from time import sleep

led = PWMLED(2)  # PWM-Pin (GPIO2)

startTemp = 45  # Temperature at which the fan switches on

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
```

#### **Make the Script Executable**
```bash
sudo chmod +x /home/menulis/fan_control.py
```

#### **Setup rc.local and Service**
```bash
# rc.local
sudo tee /etc/rc.local << 'EOF'
#!/bin/bash
# rc.local startup script

python3 /home/menulis/fan_control.py &

exit 0
EOF

sudo chmod +x /etc/rc.local

# systemd service
sudo tee /etc/systemd/system/rc-local.service << 'EOF'
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

sudo systemctl daemon-reload
sudo systemctl enable rc-local.service
sudo systemctl start rc-local.service
```

#### **Reboot**
```bash
sudo reboot
```

## Customizing the Script:
- **`startTemp`**: You can adjust this value to change the temperature at which the fan turns on.
- **PID Constants**: `pTemp` and `iTemp` control the proportional and integral parts of the fan speed adjustment. You can tweak these values to fine-tune how the fan speed responds to changes in temperature.

## Troubleshooting:
- If the fan does not respond as expected, check that the Raspberry Pi is reading the CPU temperature correctly.
- Ensure that the fan is connected to GPIO pin 2 and that it supports PWM control.

## License:
This script is provided under the [MIT License](LICENSE).
