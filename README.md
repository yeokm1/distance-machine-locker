# Distance Machine Locker

A system that locks your computer the moment you move away from it. An Arduino-based hardware senses how far are you away from the computer and reports it to a host app on your machine. When a set threshold has been reached, the machine is locked.

If the device is forcefully detached from the PC while the app is in operation, the app will lock your machine and reconnect back once the device is attached again.

Only Mac OS is supported at this time.

## Demo media

[![](http://img.youtube.com/vi/mWyIHkdfHz4/0.jpg)](https://www.youtube.com/watch?v=mWyIHkdfHz4)  
Video of everything in action.

[![](http://img.youtube.com/vi/80zMLssycmM/0.jpg)](https://www.youtube.com/watch?v=80zMLssycmM)  
Video of the talk I gave on this setup

![Screen](images/deployed.jpg)
My device deployed under my desk. The purple light coming from the sharp IR sensor cannot be seen with a naked eye but the camera can.

![Screen](images/front.jpg)
Front view of device

![Screen](images/updated-design.jpg)
This is the "production" design that does not have the OLED screen to save costs. The sensor position is shifted to take advantage of the gap in the top cover to give the wire some allowance to bend.

![Screen](images/app-distance-setting.png)  
Feature to customise the locking distance threshold.

![Screen](images/app-delay-setting.png)  
Customise a delay before locking to let you have time to get back into range.

![Screen](images/app-usb-setting.png)  
Shows the currently connected USB Serial port as well as other ports if available.

## Features

1. Locks Mac on threshold reached
2. Shows live distance reading on menubar
3. Customisable threshold from 10cm to 80cm which is the effective range of the IR sensor
4. Choice to flash firmware before connection
5. Choice to auto connect to device if only one sensor is found
6. Locks machine if device is disconnected
7. Notifications to indicate flashing/connect/disconnect status
8. If locking mode is disabled for testing purposes, a red background is placed behind the distance text to alert the user of lack of security.
9. Auto reconnect back to device if it was forcefully disconnected previously. Auto-reconnection does not happen if you manually disconnect using the menu.
10. Adjustable delay to avoid unnecessary locking if the user can come back into range within a time window.

## Rough steps to quick start

1. Build the hardware, connect it to your Mac
2. Download and install the Arduino app into `/Applications`. The Arduino app is also used by my app to flash the firmware.
2. Use Arduino app to flash firmware or flash from command line. Replace path to `distance-machine-locker-arduino.hex` and serial port `/dev/ttyusbmodemX` with the exact ones. `/Applications/Arduino.app/Contents/Java/hardware/tools/avr/bin/avrdude -C /Applications/Arduino.app/Contents/Java/hardware/tools/avr/etc/avrdude.conf -p atmega328p -b 115200 -c arduino -U flash:w:distance-machine-locker-arduino.hex:i -P /dev/ttyusbmodemX`
3. Download from releases, Unzip and copy `Distance Mac Locker.app` into `/Applications`
4. Lock the system immediately when screensaver is enabled or display sleeps. System Preferences -> Security and Privacy -> Require password "immediately"
5. Start the app
6. Connect to the associated USB Serial port
7. Turn off locking mode and decide your threshold distance
8. Set your threshold distance and turn locking mode back on
9. Optionally turn on `Connect on Start` and `Flash before Connect`. Configure locking delay if you want.
10. Make app start on login by. System Preferences -> Users and Groups -> Login Items -> + app into list

## Documentation

Extra documentation is available in the readme files of the subdirectories.

1. [Hardware schematic and components](schematic/README.md)
2. [Arduino Code](distance-machine-locker-arduino/README.md)
3. [Swift Host Code](Distance%20Mac%20Locker/README.md)
