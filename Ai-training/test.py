import cv2
import numpy as np
from tensorflow.keras.models import load_model

# Load trained model and emotion labels
model = load_model('best_model.h5')
emotion_labels = ['angry', 'happy', 'neutral','sad', 'surprise']

# Load Haar Cascade
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

# Start webcam
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Detect faces once per frame
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=5, minSize=(100, 100))

    for (x, y, w, h) in faces:
        face = gray[y:y+h, x:x+w]

        # Preprocess face
        face = cv2.equalizeHist(face)
        face = cv2.GaussianBlur(face, (3, 3), 0)
        # Convert to RGB and resize to 96x96
        face = cv2.resize(frame[y:y+h, x:x+w], (96, 96))
        face = cv2.cvtColor(face, cv2.COLOR_BGR2RGB)  # Ensure 3 channels
        face_input = face / 255.0                     # Normalize
        face_input = np.reshape(face_input, (1, 96, 96, 3))

        # Predict emotion
        prediction = model.predict(face_input, verbose=0)
        confidence = np.max(prediction)
        emotion = emotion_labels[np.argmax(prediction)]

        # Display result
        label = f"{emotion} ({confidence:.2f})"
        cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
        cv2.putText(frame, label, (x, y - 10),
        cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)

    cv2.imshow("Emotion detector", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()