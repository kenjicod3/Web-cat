//  TeacherView.swift
//  Webcat
//
//  Created by Hoang Le Minh on 19/4/25.

import SwiftUI

struct TeacherView: View {
    @State private var emotionLogs: [EmotionLog] = []
    @State private var geminiSummary: String = ""
    @State private var ssid: String = ""
    @State private var password: String = ""
    let gemini = GeminiAnalyzer()

    var body: some View {
        VStack(spacing: 20) {
            Text("Teacher Dashboard")
                .font(.title)

            VStack(alignment: .leading) {
                Text("\u{1F4F1} Wi-Fi Configuration")
                    .font(.headline)
                TextField("SSID", text: $ssid)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send to Student") {
                    ServerManager.shared.sendCredentialsToStudent(ssid: ssid, password: password, to: "127.0.0.1")
                }
                .padding(.top, 5)
            }
            .padding()

            Divider()

            if !emotionLogs.isEmpty {
                EmotionChartView(logs: emotionLogs)
                Button("Analyze with Gemini") {
                    gemini.analyzeEmotions(logs: emotionLogs) { result in
                        geminiSummary = result
                    }
                }
                if !geminiSummary.isEmpty {
                    ScrollView {
                        Text(geminiSummary)
                            .padding()
                    }
                    .frame(maxHeight: 300)
                }
            } else {
                Text("Waiting for student data...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onAppear {
            startTeacherServer { logs in
                self.emotionLogs.append(contentsOf: logs)
            }
        }
    }
}

func startTeacherServer(receive: @escaping ([EmotionLog]) -> Void) {
    Task {
        await ServerManager.shared.startServer { incomingLogs in
            receive(incomingLogs)
        }
    }
}
