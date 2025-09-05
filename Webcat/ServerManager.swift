// ServerManager.swift
// Handles TCP server for receiving data and sending credentials

import Foundation
import Network

class ServerManager: ObservableObject {
    static let shared = ServerManager()
    private var listener: NWListener?
    private var connections: [NWConnection] = []

    // Starts a TCP server to listen for logs
    func startServer(receiveLogs: @escaping ([EmotionLog]) -> Void) async {
        do {
            listener = try NWListener(using: .tcp, on: 9090)
            listener?.newConnectionHandler = { [weak self] connection in
                self?.setupConnection(connection, receiveLogs: receiveLogs)
            }
            listener?.start(queue: .main)
            print("Server started on port 9090")
            ConnectionManager.shared.publishTeacherService(port: 9090)
        } catch {
            print("Failed to start server: \(error.localizedDescription)")
        }
    }

    // Setup a connection to receive data
    private func setupConnection(_ connection: NWConnection, receiveLogs: @escaping ([EmotionLog]) -> Void) {
        connection.start(queue: .main)
        connections.append(connection)
        receiveMessage(on: connection, receiveLogs: receiveLogs)
    }

    // Receive logs from student
    private func receiveMessage(on connection: NWConnection, receiveLogs: @escaping ([EmotionLog]) -> Void) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let logs = try decoder.decode([EmotionLog].self, from: data)
                    receiveLogs(logs)
                } catch {
                    print("Failed to decode emotion logs: \(error.localizedDescription)")
                }
            }

            if isComplete || error != nil {
                connection.cancel()
            } else {
                self.receiveMessage(on: connection, receiveLogs: receiveLogs)
            }
        }
    }

    // Sends credentials to student
    func sendCredentialsToStudent(ssid: String, password: String, to host: String = "127.0.0.1" ) {
        //connect via connection manager.
        //guard let host = ConnectionManager.shared.discoveredStudentHost else {
            //print("No student IP discovered")
            //return
        //}

        let connection = NWConnection(host: NWEndpoint.Host(host), port: 8081, using: .tcp)
        connection.start(queue: .main)

        let message = "\(ssid)\n\(password)\n"
        let data = message.data(using: .utf8) ?? Data()

        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send credentials: \(error.localizedDescription)")
            } else {
                print("Credentials sent to student at \(host)")
            }
            connection.cancel()
        }))
    }
}
