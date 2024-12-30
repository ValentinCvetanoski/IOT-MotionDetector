const int PIR_PIN = 2;  // Digital pin connected to PIR sensor's OUT pin
const int LED_PIN = 13;  // Digital pin connected to LED's Anode (with resistor)

void setup() {
  pinMode(PIR_PIN, INPUT);  // Set PIR_PIN as an input
  pinMode(LED_PIN, OUTPUT);  // Set LED_PIN as an output
  Serial.begin(9600);  // Initialize serial communication for debugging
}

void loop() {
  if (digitalRead(PIR_PIN) == HIGH) {  // Check if motion is detected
    digitalWrite(LED_PIN, HIGH);  // Turn on the LED
    Serial.println("1");  // Signal to Python script
    delay(2000);  // Keep LED on for 2 seconds to avoid rapid triggering
  } else {
    digitalWrite(LED_PIN, LOW);   // Turn off the LED if no motion
  }
  delay(100);  // Small delay to debounce
}