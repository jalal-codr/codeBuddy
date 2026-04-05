//
//  ChatInputBar.swift
//  code buddy
//

import SwiftUI

struct ChatInputBar: View {
    @Binding var inputText: String
    let onSend: () -> Void
    let onStop: () -> Void
    var isGenerating: Bool = false
    var isDisabled: Bool = false

    @ObservedObject private var modelManager = OllamaModelManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.cbBorder)

            // Model + token info
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Image(systemName: "cpu").font(.system(size: 11)).foregroundColor(Color.cbAccent)
                    Text(activeModelLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.cbAccent).tracking(0.5)
                }
                HStack(spacing: 5) {
                    Image(systemName: "memorychip").font(.system(size: 11))
                        .foregroundColor(Color.cbTextSecondary)
                    Text("2048 TOKENS").font(.system(size: 10))
                        .foregroundColor(Color.cbTextSecondary).tracking(0.5)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

            // Input row
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "paperclip").font(.system(size: 14))
                        .foregroundColor(Color.cbTextSecondary).frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                TextField("Ask CodeBud anything about your stack...", text: $inputText)
                    .font(.system(size: 13))
                    .foregroundColor(Color.cbTextPrimary)
                    .textFieldStyle(.plain)
                    .disabled(isGenerating)
                    .onSubmit { if !isGenerating { onSend() } }

                // Stop button while generating, send button otherwise
                if isGenerating {
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.red.opacity(0.85))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(inputText.isEmpty || isDisabled
                                ? Color.cbAccent.opacity(0.4) : Color.cbAccent)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty || isDisabled)
                }
            }
            .padding(.horizontal, 12).padding(.bottom, 8)

            HStack {
                if isGenerating {
                    Label("Generating… tap ■ to stop", systemImage: "stop.fill")
                        .font(.system(size: 10)).foregroundColor(Color.cbTextMuted)
                } else {
                    Label("Return to send", systemImage: "return")
                        .font(.system(size: 10)).foregroundColor(Color.cbTextMuted)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.bottom, 10)
        }
        .background(Color.cbSurface)
    }

    private var activeModelLabel: String {
        modelManager.activeModelName
            .replacingOccurrences(of: ":latest", with: "")
            .uppercased()
            .prefix(20)
            .description
            .ifEmpty("MODEL")
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
