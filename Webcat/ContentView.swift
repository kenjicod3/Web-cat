import SwiftUI
import UniformTypeIdentifiers
import Charts
struct EmotionChartView: View {
    let logs: [EmotionLog]
    func emotionToIndex(_ emotion: String) -> Int {
        switch emotion {
            case "sad": return 0
            case "angry": return 1
            case "neutral": return 2
            case "surprise": return 3
            case "happy": return 4
            default: return -1
        }
    }
    var body: some View {
        Chart(logs) { log in
            LineMark(
                x: .value("Time", log.timestamp),
                y: .value("Emotion", emotionToIndex(log.emotion))
            )
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...4)
        .chartYAxis{
            AxisMarks(values:[0,1,2,3,4]){value in
                AxisGridLine()
                AxisValueLabel{
                    let labels = ["Sad", "Angry", "Neutral", "Surprise", "Happy"]
                    Text(labels[value.as(Int.self) ?? 0])
                }
            }
        }
        .frame(height: 300)
        .padding()
        
    }
}

import Foundation
import Darwin

func sendCommandToESP32(_ command: String) {
    let listPorts = Process()
    listPorts.executableURL = URL(fileURLWithPath: "/bin/zsh")
    listPorts.arguments = ["-c", "ls /dev/cu.*"]

    let pipe = Pipe()
    listPorts.standardOutput = pipe

    do {
        try listPorts.run()
        listPorts.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let portList = String(data: data, encoding: .utf8)?
            .split(separator: "\n")
            .map(String.init)
            .first(where: { $0.contains("usbserial") || $0.contains("wchusbserial") || $0.contains("SLAB_USBtoUART") }) else {
            print("ESP32 serial port not found.")
            return
        }

        print("Using ESP32 port: \(portList)")

        let fd = open(portList, O_RDWR | O_NOCTTY | O_NONBLOCK)
        if fd == -1 {
            perror("open")
            print("Failed to open serial port.")
            return
        }

        var options = termios()
        if tcgetattr(fd, &options) != 0 {
            perror("tcgetattr")
            close(fd)
            return
        }

        cfsetispeed(&options, speed_t(B115200))
        cfsetospeed(&options, speed_t(B115200))
        options.c_cflag |= tcflag_t(CLOCAL | CREAD)
        options.c_cflag &= ~tcflag_t(PARENB | CSTOPB | CSIZE)
        options.c_cflag |= tcflag_t(CS8)
        options.c_lflag = 0
        options.c_iflag = 0
        options.c_oflag = 0
        options.c_cc.16 = 1 // VMIN
        options.c_cc.17 = 0 // VTIME

        tcflush(fd, TCIFLUSH)
        if tcsetattr(fd, TCSANOW, &options) != 0 {
            perror("tcsetattr")
            close(fd)
            return
        }

        let fullCommand = command + "\n"
        if let data = fullCommand.data(using: .utf8) {
            let result = data.withUnsafeBytes {
                write(fd, $0.baseAddress, data.count)
            }

            if result > 0 {
                print("Sent command to ESP32: \(command)")
            } else {
                perror("write")
                print("Failed to write command.")
            }
        }

        close(fd)

    } catch {
        print("Error: \(error.localizedDescription)")
    }
}


class GeminiAnalyzer {
    private let apiKey = "" //put api key here

    func analyzeEmotions(logs: [EmotionLog], completion: @escaping (String) -> Void) {
        let formatter = ISO8601DateFormatter()
        let summary = logs.map {
            "\(formatter.string(from: $0.timestamp)) → \($0.emotion)"
        }.joined(separator: "\n")

        let prompt = """
        You are an assistant analyzing emotional trends in classrooms.

        Here is a time-based log of emotions:
        \(summary)

        Please summarize the mood trend and offer insight.
        """

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Gemini error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    DispatchQueue.main.async {
                        completion(text)
                    }
                } else {
                    print("Could not parse Gemini response.")
                    print(String(data: data, encoding: .utf8) ?? "No data")
                }
            }
        }.resume()
    }
}




