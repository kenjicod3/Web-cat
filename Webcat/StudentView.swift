// StudentView.swift
// Handles receiving Wi-Fi credentials and sending emotion logs

import SwiftUI
import Network

struct StudentView: View {
    @State private var status: String = "Waiting for Wi-Fi credentials..."
    @State private var credentialsReceived = false
    @State private var logsSent = false
    @State private var esp32IP: String? = nil
    @State private var connectionFailed = false
    var body: some View {
        VStack(spacing: 20) {
            Text("Student Dashboard")
                .font(.title)
            
            Text(status)
                .foregroundColor(.gray)
            
            if credentialsReceived {
                Button("Start Emotion Capture") {
                    sendCommandToESP32("start")
                    if let ip = esp32IP {
                        runEmotionDetectionScript(esp32IP: ip)
                    } else {
                        status = "No IP from ESP32 yet."
                    }
                }
                
                Button("Stop and Send Logs") {
                    sendCommandToESP32("stop")
                    terminateTestPy()
                    sendLogsToTeacher()
                }
            }
            if connectionFailed {
                Button("Retry Wi-Fi Connection") {
                    connectionFailed = false
                    status = "Retrying..."
                    credentialsReceived = false
                    StudentNetworkManager.shared.listenForCredentials { ssid, password in
                        status = "Connecting ESP32 to Wi-Fi..."
                        sendCredentialsToESP32(ssid: ssid, password: password)
                        credentialsReceived = true
                        status = "Credentials sent. Waiting for camera..."
                    }
                }
            }
        }
        .padding()
        .onAppear {
            StudentNetworkManager.shared.listenForCredentials { ssid, password in
                connectionFailed = false
                status = "Connecting ESP32 to Wi-Fi..."
                sendCredentialsToESP32(ssid: ssid, password: password)
                credentialsReceived = true
                status = "Credentials sent. Ready to capture."
            }
            readSerialFromESP32()
        }
    }
    func readSerialFromESP32() {
        let listPorts = Process()
        listPorts.executableURL = URL(fileURLWithPath: "/bin/zsh")
        listPorts.arguments = ["-c", "ls /dev/cu.*"]

        let pipe = Pipe()
        listPorts.standardOutput = pipe

        do {
            try listPorts.run()
            listPorts.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            guard let portPath = String(data: data, encoding: .utf8)?
                .split(separator: "\n")
                .map(String.init)
                .first(where: { $0.contains("usbserial") || $0.contains("wchusbserial") || $0.contains("SLAB_USBtoUART") }) else {
                print("ESP32 serial port not found.")
                return
            }

            print("📡 Reading from ESP32 port: \(portPath)")

            let fd = open(portPath, O_RDONLY | O_NOCTTY | O_NONBLOCK)
            if fd == -1 {
                perror("open")
                print("Failed to open serial port.")
                return
            }

            var buffer = [UInt8](repeating: 0, count: 1024)
            var readData = ""

            DispatchQueue.global().async {
                while true {
                    let count = read(fd, &buffer, buffer.count)
                    if count > 0 {
                        let chunk = String(decoding: buffer[0..<count], as: UTF8.self)
                        readData += chunk

                        // Handle lines
                        let lines = readData.components(separatedBy: "\n")
                        for line in lines where !line.isEmpty {
                            DispatchQueue.main.async {
                                print("ESP32:", line)

                                if line.contains("Wi-Fi connection failed") {
                                    connectionFailed = true
                                    status = "Wi-Fi connection failed. Tap to retry."
                                }

                                if line.hasPrefix("[CAMERA_STREAM_URL]") {
                                    let url = line.replacingOccurrences(of: "[CAMERA_STREAM_URL]", with: "")
                                    if let ip = URL(string: url)?.host {
                                        esp32IP = ip
                                        status = "📷 Stream ready at \(url)"
                                    }
                                }
                            }
                        }

                        readData = ""
                    }

                    usleep(100_000) // Poll every 100ms
                }
            }

        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

func sendCredentialsToESP32(ssid: String, password: String) {
    let combined = ssid + "\n" + password + "\n"
    sendCommandToESP32(combined)
}

func runEmotionDetectionScript(esp32IP: String) {
    guard let modelPath = Bundle.main.path(forResource: "best_model", ofType: "h5"),
          let scriptPath = Bundle.main.path(forResource: "test", ofType: "py") else {
        print("Missing script or model")
        return
    }
    let streamURL = "http://\(esp32IP):81/stream"

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    process.arguments = ["-u", scriptPath, modelPath, streamURL]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        print("Running emotion detection script with stream: \(streamURL)")
    } catch {
        print("Failed to run Python: \(error.localizedDescription)")
    }
    pipe.fileHandleForReading.readabilityHandler = { handle in
        let output = String(data: handle.availableData, encoding: .utf8) ?? ""
        print("Output:\n\(output)")
    }
}


func terminateTestPy() {
    let killProcess = Process()
    killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
    killProcess.arguments = ["-f", "test.py"]

    do {
        try killProcess.run()
        killProcess.waitUntilExit()
        print("Terminated test.py")
    } catch {
        print("Failed to terminate test.py: \(error.localizedDescription)")
    }
}

func sendLogsToTeacher() {
    StudentNetworkManager.shared.sendLogsFromDocuments()
}

