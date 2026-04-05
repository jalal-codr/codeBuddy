//
//  ServiceStatusPanel.swift
//  code buddy
//

import SwiftUI

struct ServiceStatusPanel: View {
    @Binding var isRunInBackground: Bool
    @ObservedObject private var ollama = OllamaManager.shared

    var body: some View {
        VStack(spacing: 10) {
            // Ollama status card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.cbTextSecondary)
                    Spacer()
                    Text("SERVICE STATUS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.cbTextSecondary).tracking(0.8)
                }

                Text("Ollama Backend")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.cbTextPrimary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(ollama.isRunning ? Color.cbGreen : Color.red)
                        .frame(width: 6, height: 6)
                    Text(ollama.statusText)
                        .font(.system(size: 12))
                        .foregroundColor(ollama.isRunning ? Color.cbGreen : .red)
                }

                HStack {
                    Text("Host: 127.0.0.1:11434")
                        .font(.system(size: 11))
                        .foregroundColor(Color.cbTextSecondary)
                    Spacer()
                    Button("RESTART") {
                        ollama.restart()
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.cbAccent)
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.cbCard).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))

            // Run in background toggle
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(Color.cbAccent).font(.system(size: 16))
                    Text("Run in Background")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.cbTextPrimary)
                    Spacer()
                    Toggle("", isOn: $isRunInBackground)
                        .toggleStyle(.switch).tint(Color.cbAccent).scaleEffect(0.8)
                }
                Text("Persist model in RAM for instant inference across sessions.")
                    .font(.system(size: 11))
                    .foregroundColor(Color.cbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.cbCard).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))
        }
        .frame(width: 220)
    }
}
