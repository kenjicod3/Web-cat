import os
import sys
import json
import time
from datetime import datetime, timezone
import pathlib
import subprocess

# ========== Auto-install missing dependencies ==========
def install_and_import(pkg, pip_name=None):
    try:
        return __import__(pkg)
    except ImportError:
        print(f"Installing {pkg}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", pip_name or pkg])
        return __import__(pkg)

# ========== Required imports ==========
tf = install_and_import("tensorflow")
cv2 = install_and_import("cv2", "opencv-python")
np = install_and_import("numpy")

from tensorflow.keras.models import load_model

if len(sys.argv) < 3:
    print("Usage: python test.py <model_path> <stream_url>")
    sys.exit(1)

model_path = sys.argv[1]
stream_url = sys.argv[2]

# ========== Load model and labels ==========
print(f"Loading model: {model_path}")
model = load_model(model_path)
emotion_labels = ['angry', 'happy', 'neutral', 'sad', 'surprise']

# ========== Setup directories ==========
documents_dir = pathlib.Path.home() / "Documents"
emotion_folder = documents_dir / "EmotionLogs"
image_folder = emotion_folder / "Images"
emotion_folder.mkdir(parents=True, exist_ok=True)
image_folder.mkdir(parents=True, exist_ok=True)

json_path = emotion_folder / "emotion_log.json"
with open(json_path, 'w') as f:
    json.dump([], f)

logs = []

# ========== Setup face detector ==========
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

# ========== Connect to ESP32 stream ==========
print(f"Connecting to stream: {stream_url}")
cap = cv2.VideoCapture(stream_url)

if not cap.isOpened():
    print("Failed to open stream.")
    sys.exit(1)

print("Stream opened. Running...")

last_logged_time = time.time()

try:
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Frame not received.")
            continue

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=5, minSize=(100, 100))

        for (x, y, w, h) in faces:
            face = gray[y:y+h, x:x+w]
            face = cv2.equalizeHist(face)
            face = cv2.GaussianBlur(face, (3, 3), 0)
            face = cv2.resize(frame[y:y+h, x:x+w], (96, 96))
            face = cv2.cvtColor(face, cv2.COLOR_BGR2RGB)
            face = face / 255.0
            face_input = np.reshape(face, (1, 96, 96, 3))

            prediction = model.predict(face_input, verbose=0)
            confidence = np.max(prediction)
            emotion = emotion_labels[np.argmax(prediction)]
            timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")

            print(f"Detected: {emotion} ({confidence:.2f})")

            if time.time() - last_logged_time >= 30:
                logs.append({
                    "timestamp": timestamp,
                    "emotion": emotion
                })

                with open(json_path, 'w') as f:
                    json.dump(logs, f, indent=2)

                filename = image_folder / f"{timestamp}.jpg"
                cv2.imwrite(str(filename), frame)

                print(f"[{timestamp}] Emotion logged: {emotion}")
                last_logged_time = time.time()

        time.sleep(0.1)

except KeyboardInterrupt:
    print("Exiting...")

finally:
    cap.release()
