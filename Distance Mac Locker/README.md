# Distance Mac locker

This is the host app portion of the system. It receives distance data via a USB cable from the Arduino hardware. The distance data is compared to a provided threshold and the Mac is locked should the threshold be met.

App is written in Swift and is considered a Menubar App as lives in the OSX menubar and does not have a main Window.

## Setting up

1. Make sure you install the Arduino app into `/Applications` before you proceed

2. Download and install the latest Xcode which is version 8.2.1 at the time of writing

3. Open `Distance Mac Locker.xcodeproj`

4. If you have modified the Arduino code and regenerated the hex file, drag and drop the new hex file into the Xcode project before recompiling.

## Libraries and images used
1. Serial Port communication with the Arduino is handled with my [SwiftSerial](https://github.com/yeokm1/SwiftSerial) library. I'm unsure how to use Swift Package Manager with Xcode so I just dropped the code of the entire library in.
2. [Lock icon as app icon](https://www.iconfinder.com/icons/314694/lock_open_icon)
