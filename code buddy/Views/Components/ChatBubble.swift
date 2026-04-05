//
//  ChatBubble.swift
//  code buddy
//

import SwiftUI
import AppKit

struct ChatBubble: View {
    let message: ChatMessage
    let onEdit: ((String) -> Void)?
    @State private var copied: Bool = false

    init(message: ChatMessage, onEdit: ((String) -> Void)? = nil) {
        self.message = message
        self.onEdit = onEdit
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(message.isUser ? Color.cbCard : Color.cbAccent)
                    .frame(width: 32, height: 32)
                Image(systemName: message.isUser ? "person" : "bolt.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(message.isUser ? Color.cbTextSecondary : .white)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Header row
                HStack(spacing: 8) {
                    Text(message.isUser ? "You" : "CodeBud AI")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(message.isUser ? Color.cbTextPrimary : Color.cbAccent)
                    Text(message.time)
                        .font(.system(size: 10))
                        .foregroundColor(Color.cbTextMuted)
                    if !message.isUser && !message.isThinking {
                        modelBadge
                    }
                    Spacer()
                    // Edit button on user messages
                    if message.isUser, let onEdit {
                        editButton(onEdit: onEdit)
                    }
                    // Copy button on AI responses
                    if !message.isUser && !message.isThinking {
                        copyButton
                    }
                }

                // Body — loader or text
                if message.isThinking {
                    ThinkingDots()
                } else {
                    Text(message.text)
                        .font(.system(size: 13))
                        .foregroundColor(message.isUser
                            ? Color.cbTextPrimary.opacity(0.9)
                            : Color.cbTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var modelBadge: some View {
        let name = OllamaModelManager.shared.activeModelName
            .replacingOccurrences(of: ":latest", with: "")
            .uppercased()
        return Text(name.isEmpty ? "AI" : name)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(Color.cbTextMuted)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(Color.cbCard).cornerRadius(3)
    }

    private func editButton(onEdit: @escaping (String) -> Void) -> some View {
        Button(action: { onEdit(message.text) }) {
            HStack(spacing: 3) {
                Image(systemName: "pencil").font(.system(size: 10))
                Text("Edit").font(.system(size: 10))
            }
            .foregroundColor(Color.cbTextMuted)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.cbCard).cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cbBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var copyButton: some View {
        Button(action: copyToClipboard) {
            HStack(spacing: 3) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
                Text(copied ? "Copied" : "Copy")
                    .font(.system(size: 10))
            }
            .foregroundColor(copied ? Color.cbGreen : Color.cbTextMuted)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.cbCard).cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4)
                .stroke(copied ? Color.cbGreen.opacity(0.4) : Color.cbBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.text, forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}

// MARK: - Animated thinking dots

struct ThinkingDots: View {
    @State private var phase: Int = 0

    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.cbAccent)
                    .frame(width: 7, height: 7)
                    .opacity(phase == i ? 1.0 : 0.25)
                    .scaleEffect(phase == i ? 1.1 : 0.85)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .padding(.vertical, 6)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}
