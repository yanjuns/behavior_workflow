//Includes the Arduino Stepper Library
#include <Stepper.h>

// Defines the number of steps per rotation
const int stepsPerRevolution = 2038;

// Creates an instance of stepper class
// Pins entered in sequence IN1-IN3-IN2-IN4 for proper step sequence
Stepper myStepper = Stepper(stepsPerRevolution, 8, 10, 9, 11);

// define pin number
int bonsaiPin = 0;

void setup() {
  Serial.begin(9600);
}

void loop() {
  if (Serial.available() > 0) {
    //if (digitalRead(bonsaiPin) == LOW)
    // read the incoming byte:
    bool rotate = Serial.read();
    Serial.println(rotate, BIN);
    if (rotate == 0) {
      // Rotate CW at 15 RPM
      myStepper.setSpeed(15);
      myStepper.step(stepsPerRevolution);
    }
  }
}