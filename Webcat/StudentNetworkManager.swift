import Foundation
import Network

class StudentNetworkManager {
    static let shared = StudentNetworkManager()

    private var listener: NWListener?
    private var teacherHost: String?
    private var teacherPort: UInt16 = 9090

    // Start TCP listener to receive Wi-Fi credentials from teacher
    func listenForCredentials(completion: @escaping (_ ssid: String, _ password: String) -> Void) {
        do {
            listener = try NWListener(using: .tcp, on: 8081)
        } catch {
            print("Failed to start TCP listener: \(error)")
            return
        }

        listener?.newConnectionHandler = { connection in
            connection.start(queue: .main)
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
                if let data = data,
                   let credentials = String(data: data, encoding: .utf8) {
                    let parts = credentials.split(separator: "\n").map(String.init)
                    if parts.count >= 2 {
                        let ssid = parts[0]
                        let password = parts[1]
                        print("Received SSID: \(ssid)")
                        print("Received Password: \(password)")
                        completion(ssid, password)
                    } else {
                        print("Received malformed credentials")
                    }
                }
            }
        }

        listener?.start(queue: .main)
        print("🎧 Listening for Wi-Fi credentials on port 8081")
    }

    // Send emotion log JSON back to teacher
    func sendLogsFromDocuments() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not find Documents directory")
            return
        }

        let logURL = documentsURL.appendingPathComponent("EmotionLogs/emotion_log.json")
        guard FileManager.default.fileExists(atPath: logURL.path) else {
            print("No emotion log file to send")
            return
        }

        do {
            let jsonData = try Data(contentsOf: logURL)
            sendEmotionLog(to: teacherHost ?? "127.0.0.1", jsonData: jsonData)
        } catch {
            print("Failed to read JSON log: \(error.localizedDescription)")
        }
    }

    private func sendEmotionLog(to host: String, jsonData: Data) {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: teacherPort)!, using: .tcp)

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connected to teacher at \(host)")
                connection.send(content: jsonData, completion: .contentProcessed({ error in
                    if let error = error {
                        print("Failed to send JSON: \(error)")
                    } else {
                        print("Sent emotion log to teacher")
                    }
                    connection.cancel()
                }))
            case .failed(let error):
                print("Connection failed: \(error.localizedDescription)")
            default:
                break
            }
        }

        connection.start(queue: .main)
    }
}


