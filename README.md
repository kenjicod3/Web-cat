# ESP32-CAM Emotion Recognition System  

This repository contains the source code and materials for my **Term 2 Design Thinking and Innovation (DTI) project at SUTD**. The project integrates hardware (ESP32-CAM), AI-based emotion recognition, and application development (macOS/Swift + Python) to track student emotions in classroom settings and provide data visualization for teachers.  

## Project Overview  
- Student side (ESP32-CAM + Student App):  
  - ESP32-CAM captures images periodically and streams them over USB Serial.  
  - A Python script (`test.py`) receives the images, runs emotion classification with a MobileNetV3 model, and logs results in JSON format.  
  - A macOS Swift app (Student App) connects to the pipeline, processes local data, and (optionally) sends logs to the Teacher App.  

- Teacher side (Teacher App):  
  - Receives JSON log files or data streams from student devices.  
  - Parses and visualizes the data into emotion-over-time graphs.  
  - Supports additional analysis using Gemini API (via a secure local secret).  

- Training:  
  - A separate folder contains scripts and notebooks to train and fine-tune the MobileNetV3 model for facial emotion recognition.  

- The setup file for the ESP32 cam through Arduino is included.

## Tech Stack  
- Hardware: ESP32-CAM (AI Thinker)  
- Languages: Python, C++, Swift  
- Libraries & Tools: OpenCV, TensorFlow/Keras, NumPy, PySerial, SwiftUI, Xcode, Git  

## Setup Instructions

ESP32-CAM

Upload the Arduino sketch into the camera using Arduino IDE.

## App features

macOS Applications

Student App (SwiftUI): Connects to the camera via the Python backend and manages local logs.

Teacher App (SwiftUI): Receives JSON logs from student devices and visualizes them as graphs.

A Gemini API key is required for advanced text-based analysis.
This repository provides only the source code for packaging the macOS applications. Detailed packaging instructions are not included. Please contact me if you require the packaged application files, or you may package the apps yourself using the provided source code.


## Notes  
- This project was completed as part of SUTD Term 2 – Design Thinking and Innovation (DTI).  
- The repository is archived as a reference of work done; it is no longer actively maintained.  
- Datasets and training models are included. 

## Author  
**Minh Le (kenjicod3)**  
- CTO at GameChangers (Create4Good SUTD 2025 Winner)
- Computer Science & Design @ SUTD  
- LinkedIn: https://www.linkedin.com/in/minh-ho%C3%A0ng-l%C3%AA-ab724032a
- GitHub: https://github.com/kenjicod3  
