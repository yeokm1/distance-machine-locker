# Distance Machine Locker

A system that locks your computer the moment you move away from it. An Arduino-based hardware senses how far are you away from the computer and reports it to a host app on your machine. When a set threshold has been reached, the

Only Mac OS is supported at this time.

## Demo media

[![](http://img.youtube.com/vi/mWyIHkdfHz4/0.jpg)](https://www.youtube.com/watch?v=mWyIHkdfHz4)

Video of everything in action.

![Screen](images/deployed.jpg)
My device deployed under my desk. The purple light is coming from the sharp IR sensor.

![Screen](images/front.jpg)
Front view of device

![Screen](images/back.jpg)
Back view of device. The OLED screen shows the current distance.

## Features

1. Locks Mac on threshold reached
2. Shows live distance reading on menubar
3. Customisable threshold from 10cm to 80cm which is the effective range of the IR sensor
4. Choice to flash firmware before connection
5. Choice to auto connect to device if only one sensor is found
6. Locks machine if device is disconnected
7. Notifications to indicate flashing/connect/disconnect status

## Documentation

Extra documentation is available in the readme files of the subdirectories.

1. [Hardware schematic and components](schematic/README.md)
2. [Arduino Code](distance-machine-locker-arduino/README.md)
3. [Swift Host Code](Distance Mac Locker/README.md)
