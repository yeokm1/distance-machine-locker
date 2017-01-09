# Distance Machine Locker Arduino

This is the code that runs on the Arduino Uno that measures the distance with a Sharp IR sensor before transmitting it over to the host machine over the USB-Serial cable. Distance in centimetres is sent at a rate of 5 times a second.

## Setting up the Arduino IDE on the Mac

1. Download the [Arduino IDE](https://www.arduino.cc/en/Main/Software) which is version 1.8.0 at the time of writing.

2. Make sure to copy the `Arduino.app` to the `/Applications` directory as part of its internal binary `avrdude` will be used by the Swift host app.

3. Open the `distance-machine-locker-arduino.ino` file.

4. Click Sketch -> Include Library -> Manage Libraries

5. Search and install the libraries `Adafruit GFX Library` and `Adafruit SSD1306`. This step is optional if you don't intend to use the OLED. Just comment out the `#define USING_OLED TRUE` the line.

6. Connect the Arduino setup, select `Arduino/Genuino Uno` as the board and you can upload the firmware.

7. Since the host app has the option to reprogram the board, we should export the binary. Sketch -> Export compiled Binary. Save it as something like `distance-machine-locker-arduino.hex` so we can use it later.


## Included library
1. [SharpIR library](https://github.com/guillaume-rico/SharpIR)
