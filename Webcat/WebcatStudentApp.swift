//
//  WebcatStudentApp.swift
//  Webcat
//
//  Created by Hoang Le Minh on 19/4/25.
//


import SwiftUI

@main
struct WebcatStudentApp: App {
    var body: some Scene {
        WindowGroup {
            StudentView()
        }
        .windowStyle(DefaultWindowStyle()) // optional
        .defaultSize(width: 900, height: 600) 
    }
}
