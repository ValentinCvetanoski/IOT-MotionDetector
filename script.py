import cv2
import serial
import time
import requests

# Telegram Bot Configuration
BOT_TOKEN = "***************************"
CHAT_ID = "**************"

def send_telegram_message(message):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": CHAT_ID,
        "text": message
    }
    try:
        response = requests.post(url, json=payload)
        if response.status_code == 200:
            print("Notification sent successfully!")
        else:
            print(f"Failed to send notification. Response: {response.text}")
    except Exception as e:
        print(f"Error sending notification: {e}")

def send_telegram_photo(photo_path, caption=""):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendPhoto"
    try:
        with open(photo_path, "rb") as photo:
            payload = {"chat_id": CHAT_ID, "caption": caption}
            files = {"photo": photo}
            response = requests.post(url, data=payload, files=files)
            if response.status_code == 200:
                print("Photo sent successfully!")
            else:
                print(f"Failed to send photo. Response: {response.text}")
    except Exception as e:
        print(f"Error sending photo: {e}")

# Ubidots Configuration
UBIDOTS_TOKEN = "**************************"
UBIDOTS_DEVICE_LABEL = "motion_detector"
UBIDOTS_VARIABLE = "notification"

def send_to_ubidots(name):
    url = f"https://industrial.api.ubidots.com/api/v1.6/devices/{UBIDOTS_DEVICE_LABEL}/"
    headers = {
        "X-Auth-Token": UBIDOTS_TOKEN,
        "Content-Type": "application/json"
    }
    payload = {
        UBIDOTS_VARIABLE: {
            "value": 1,
            "context": {"person": name}
        }
    }
    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 200:
            print("Data sent to Ubidots successfully!")
        else:
            print(f"Failed to send data to Ubidots. Response: {response.text}")
    except Exception as e:
        print(f"Error sending data to Ubidots: {e}")

# Serial communication setup with Arduino
arduino = serial.Serial('COM3', 9600, timeout=1)  # Adjust 'COM3' to your Arduino's port
time.sleep(2)  # Wait for Arduino to initialize
print(f"Arduino serial connection status: {arduino.is_open}")

# Initialize camera capture
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 480)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 640)
if not cap.isOpened():
    print("Error: Camera could not be opened.")
    exit()

print("Camera capture initialized.")

# Load Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_alt2.xml")

print("Starting main loop...")
while True:
    print("Loop running...")
    time.sleep(0.1)  # Small delay to reduce CPU usage

    if arduino.in_waiting > 0:
        incomingData = arduino.readline().decode('utf-8').strip()
        print(f"Received from Arduino: {incomingData}")
        if incomingData == '1':
            print("Motion detected by Arduino.")

            ret, frame = cap.read()
            if not ret:
                print("Failed to grab frame")
                continue

            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            gray = cv2.equalizeHist(gray)  # Improve contrast

            # Detect faces
            faces = face_cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,  # Fine-tuned for better precision
                minNeighbors=8,   # Increased to reduce false positives
                minSize=(75, 75)  # Larger size for better detection
            )

            if len(faces) == 0:
                print("No face detected. Discarding frame.")
                continue

            for (x, y, w, h) in faces:
                # Save and send the frame to Telegram
                img_path = "guest.jpg"
                cv2.imwrite(img_path, frame)
                send_telegram_photo(img_path, caption="Motion detected! You have a guest.")

                # Draw rectangle around face
                cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

            # Show the frame for debugging
            cv2.imshow("Video", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    if cv2.waitKey(1) & 0xFF == ord('q'):
        print("Exiting program.")
        break

# Cleanup
cap.release()
cv2.destroyAllWindows()
arduino.close()
print("Program ended, resources cleaned up.")
