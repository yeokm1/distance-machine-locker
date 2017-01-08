#define USING_OLED TRUE

#ifdef USING_OLED
  #include <SPI.h>
  #include <Wire.h>
  #include <Adafruit_GFX.h>
  #include <Adafruit_SSD1306.h>
  #define OLED_RESET 4
  Adafruit_SSD1306 display(OLED_RESET);
#endif

#include "SharpIR.h"

#define PIN_13 13

#define PIN_DISTANCE_SENSOR A0
#define model 1080 //1080 for GP2Y0A21Y

SharpIR SharpIR(PIN_DISTANCE_SENSOR, model);

void setup() {
  Serial.begin(9600);

  pinMode(PIN_13, OUTPUT);
  digitalWrite(PIN_13, LOW);

#ifdef USING_OLED
  display.begin(SSD1306_SWITCHCAPVCC, 0x3D);  // initialize with the I2C addr 0x3D (for the 128x64)
  display.setTextSize(4);
  display.setTextColor(WHITE);
  display.clearDisplay();
#endif
}

void loop() {
  delay(200);   

  int distance = SharpIR.distance();  // this returns the distance to the object you're measuring

#ifdef USING_OLED
  display.clearDisplay();
  display.setCursor(60,0);
  display.println(distance);
  display.display();
#endif

  Serial.println(distance);
}
