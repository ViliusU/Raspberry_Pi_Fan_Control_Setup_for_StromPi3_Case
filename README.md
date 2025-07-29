
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

### 1. **Update and Upgrade the System**
Run the following commands to update and upgrade your Raspberry Pi's package list and installed packages:

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt update && sudo apt upgrade -y
```

### 2. **Install Required Packages**
Install Python 3 and the necessary libraries for controlling the GPIO pins:

```bash
sudo apt install -y python3-full
sudo apt-get install -y python3-gpiozero python3-rpi.gpio
```

### 3. **Download and Create the Fan Control Script**
Create the `fan_control.py` script that will manage the fan based on CPU temperature:

```bash
nano /home/pi/fan_control.py
```

Paste the following Python script into the file:

```python
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
```

### 4. **Make the Script Executable**
Grant execution permissions for the script:

```bash
sudo chmod +x /home/pi/fan_control.py
```

### 5. **Set the Script to Run on Boot**
To run the script automatically when the Raspberry Pi boots, modify the `rc.local` file to include the script:

```bash
sudo sed -i '$i \python3 /home/pi/fan_control.py &' /etc/rc.local
```

### 6. **Make `rc.local` Executable**
Ensure that the `rc.local` file is executable so it runs properly:

```bash
sudo chmod +x /etc/rc.local
```

### 7. **Enable and Check rc.local Service**
Make sure the `rc.local` service is enabled and check its status:

```bash
sudo systemctl enable rc-local.service
sudo systemctl status rc-local.service
```

### 8. **Reboot Your Raspberry Pi**
Finally, reboot your Raspberry Pi to apply the changes:

```bash
sudo reboot
```

After the reboot, the fan control script will run automatically at startup and adjust the fan speed based on the CPU temperature.

## Customizing the Script:
- **`startTemp`**: You can adjust this value to change the temperature at which the fan turns on.
- **PID Constants**: `pTemp` and `iTemp` control the proportional and integral parts of the fan speed adjustment. You can tweak these values to fine-tune how the fan speed responds to changes in temperature.

## Troubleshooting:
- If the fan does not respond as expected, check that the Raspberry Pi is reading the CPU temperature correctly.
- Ensure that the fan is connected to GPIO pin 2 and that it supports PWM control.

## License:
This script is provided under the [MIT License](LICENSE).
