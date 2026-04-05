//
//  code_buddyApp.swift
//  code buddy
//

import SwiftUI

@main
struct code_buddyApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        OllamaManager.shared.start()
    }
    func applicationWillTerminate(_ notification: Notification) {
        OllamaManager.shared.stop()
    }
}
