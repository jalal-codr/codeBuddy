//
//  SetupView.swift
//  code buddy
//

import SwiftUI
import AppKit

struct SetupView: View {
    @StateObject private var backend = BackendManager.shared

    @State private var selectedFolderURL: URL?
    @State private var submittedPath: String?
    @State private var pendingPath: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(isUser: false,
                    text: "Hey! I'm CodeBud. You can chat with me directly, or select a project folder and index it for codebase-aware answers.",
                    time: "now")
    ]
    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            topBar

            FolderPickerBar(
                pendingPath: $pendingPath,
                submittedPath: submittedPath,
                onBrowse: browseFolder,
                onConfirm: confirmAndIndex
            )

            // Indexing progress banner
            if backend.isIndexing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text(backend.indexStatus)
                        .font(.system(size: 11))
                        .foregroundColor(Color.cbTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.cbCard)
                .overlay(Divider().background(Color.cbBorder), alignment: .bottom)
            }

            // Error banner
            if !backend.lastError.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                    Text(backend.lastError)
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
                .overlay(Divider().background(Color.cbBorder), alignment: .bottom)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(messages) { msg in
                            ChatBubble(message: msg, onEdit: msg.isUser ? { text in
                                editMessage(msg, text: text)
                            } : nil)
                            .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .background(Color.cbBackground)

            ChatInputBar(
                inputText: $inputText,
                onSend: sendMessage,
                onStop: stopGeneration,
                isGenerating: backend.isAsking,
                isDisabled: backend.isIndexing
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cbBackground)
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal").font(.system(size: 12))
                .foregroundColor(Color.cbTextSecondary)
            Text("Setup").font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.cbTextSecondary).tracking(1)
            Image(systemName: "chevron.right").font(.system(size: 10))
                .foregroundColor(Color.cbTextMuted)
            Text("Project & Chat").font(.system(size: 12))
                .foregroundColor(Color.cbTextPrimary)
            Spacer()
            // Mode badge
            HStack(spacing: 4) {
                Circle()
                    .fill(backend.hasIndex ? Color.cbGreen : Color.cbAccent)
                    .frame(width: 6, height: 6)
                Text(backend.hasIndex ? "RAG MODE" : "DIRECT CHAT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(backend.hasIndex ? Color.cbGreen : Color.cbAccent)
                    .tracking(0.5)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background((backend.hasIndex ? Color.cbGreen : Color.cbAccent).opacity(0.1))
            .cornerRadius(4)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Color.cbBackground)
        .overlay(Divider().background(Color.cbBorder), alignment: .bottom)
    }

    // MARK: - Browse
    private func browseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Select Project Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedFolderURL = url
            pendingPath = url.path
        }
    }

    // MARK: - Confirm → index
    private func confirmAndIndex() {
        guard !pendingPath.isEmpty else { return }

        guard OllamaManager.shared.isPortOpen() else {
            appendMessage(isUser: false,
                text: "⚠️ Ollama isn't running yet. Give it a few seconds to start, then try again.")
            return
        }

        let path = pendingPath
        submittedPath = path
        let name = URL(fileURLWithPath: path).lastPathComponent

        appendMessage(isUser: false,
            text: "Got it! Indexing \"\(name)\"… this may take a minute depending on the size of your codebase.")

        backend.index(path: path) { [self] success in
            if success {
                appendMessage(isUser: false,
                    text: "✅ \"\(name)\" is indexed and ready. Ask me anything about it.")
            } else {
                appendMessage(isUser: false,
                    text: "❌ Indexing failed: \(backend.lastError). Make sure Ollama is running with the `nomic-embed-text` model pulled.")
            }
        }
    }

    // MARK: - Send — routes to RAG ask or direct chat
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !backend.isAsking else { return }

        appendMessage(isUser: true, text: trimmed)
        inputText = ""

        let thinkingMsg = ChatMessage(isUser: false, text: "", time: currentTime(), isThinking: true)
        messages.append(thinkingMsg)

        let handler: (String?) -> Void = { [self] answer in
            messages.removeAll { $0.id == thinkingMsg.id }
            if let answer, !answer.isEmpty {
                appendMessage(isUser: false, text: answer)
            } else {
                appendMessage(isUser: false, text: "❌ No answer received. \(backend.lastError)")
            }
        }

        // Use RAG if a folder has been indexed, otherwise direct chat
        if backend.hasIndex {
            backend.ask(question: trimmed, completion: handler)
        } else {
            backend.chat(message: trimmed, completion: handler)
        }
    }

    private func appendMessage(isUser: Bool, text: String) {
        messages.append(ChatMessage(isUser: isUser, text: text, time: currentTime()))
    }

    // MARK: - Stop generation

    private func stopGeneration() {
        backend.cancelGeneration()
        // Remove the thinking bubble if still present
        messages.removeAll { $0.isThinking }
        appendMessage(isUser: false, text: "⏹ Generation stopped.")
    }

    // MARK: - Edit a user message

    private func editMessage(_ message: ChatMessage, text: String) {
        guard !backend.isAsking else { return }
        // Find the message index and remove it plus everything after it
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages.removeSubrange(idx...)
        }
        // Put the text back in the input field
        inputText = text
    }
}
