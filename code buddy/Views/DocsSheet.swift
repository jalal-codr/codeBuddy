//
//  DocsSheet.swift
//  code buddy
//

import SwiftUI

struct DocsSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedSection: DocSection = .gettingStarted

    enum DocSection: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case chat           = "Chat"
        case ragMode        = "RAG Mode"
        case models         = "Models"
        case settings       = "Settings"

        var icon: String {
            switch self {
            case .gettingStarted: return "play.circle"
            case .chat:           return "bubble.left.and.bubble.right"
            case .ragMode:        return "folder.badge.magnifyingglass"
            case .models:         return "cpu"
            case .settings:       return "gearshape"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Documentation")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.cbTextPrimary)
                    .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 12)

                ForEach(DocSection.allCases, id: \.self) { section in
                    Button(action: { selectedSection = section }) {
                        HStack(spacing: 8) {
                            Image(systemName: section.icon)
                                .font(.system(size: 12))
                                .foregroundColor(selectedSection == section ? .white : Color.cbTextSecondary)
                                .frame(width: 16)
                            Text(section.rawValue)
                                .font(.system(size: 12, weight: selectedSection == section ? .medium : .regular))
                                .foregroundColor(selectedSection == section ? .white : Color.cbTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(selectedSection == section ? Color.cbAccent : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
                Spacer()
            }
            .frame(width: 180)
            .background(Color.cbSurface)

            Divider().background(Color.cbBorder)

            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(selectedSection.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.cbTextPrimary)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.cbTextSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.cbCard).cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color.cbSurface)
                .overlay(Divider().background(Color.cbBorder), alignment: .bottom)

                ScrollView {
                    docContent(for: selectedSection)
                        .padding(24)
                }
                .background(Color.cbBackground)
            }
        }
        .frame(width: 700, height: 500)
        .background(Color.cbBackground)
    }

    @ViewBuilder
    private func docContent(for section: DocSection) -> some View {
        switch section {
        case .gettingStarted: gettingStartedContent
        case .chat:           chatContent
        case .ragMode:        ragContent
        case .models:         modelsContent
        case .settings:       settingsContent
        }
    }

    // MARK: - Getting Started

    private var gettingStartedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DocParagraph(text: "Welcome to CodeBud — a local AI coding assistant powered by Ollama. Everything runs on your machine. No data leaves your computer.")

            DocStep(number: "1", title: "Install Ollama",
                    text: "Download and install Ollama from ollama.com. CodeBud will start it automatically when you launch the app.")

            DocStep(number: "2", title: "Install models",
                    text: "Go to the Models tab and click \"Model Store\". Install at least one chat model (e.g. Llama 3 or Qwen 2.5 Coder) and the nomic-embed-text embedding model if you want RAG mode.")

            DocStep(number: "3", title: "Start chatting",
                    text: "Go to the Setup tab. You can chat directly with any installed model right away — no folder needed.")

            DocStep(number: "4", title: "Index a codebase (optional)",
                    text: "Click Browse, select your project folder, then click Confirm. CodeBud will index your code and switch to RAG mode, giving context-aware answers about your codebase.")

            DocNote(text: "The nomic-embed-text model is required for indexing. Install it from the Model Store before trying to index a folder.")
        }
    }

    // MARK: - Chat

    private var chatContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DocParagraph(text: "The Setup tab is your main chat interface. It works in two modes depending on whether you've indexed a folder.")

            DocItem(title: "Direct Chat mode",
                    text: "No folder needed. Type any question and the selected model responds directly. Great for general coding questions, explanations, and brainstorming.")

            DocItem(title: "RAG mode",
                    text: "After indexing a folder, questions are answered using your actual codebase as context. The model only sees relevant chunks of your code.")

            DocItem(title: "Mode indicator",
                    text: "The badge in the top-right of the chat header shows DIRECT CHAT or RAG MODE so you always know which mode is active.")

            DocItem(title: "Copy responses",
                    text: "Every AI response has a Copy button in the top-right corner. Click it to copy the full response to your clipboard.")

            DocNote(text: "The chat input is always enabled. You don't need to index a folder to start chatting.")
        }
    }

    // MARK: - RAG Mode

    private var ragContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DocParagraph(text: "RAG (Retrieval-Augmented Generation) lets CodeBud answer questions about your specific codebase by finding the most relevant code chunks before generating a response.")

            DocStep(number: "1", title: "Install nomic-embed-text",
                    text: "This embedding model is required. Install it from Models → Model Store.")

            DocStep(number: "2", title: "Select your project folder",
                    text: "In the Setup tab, click Browse and select the root of your project.")

            DocStep(number: "3", title: "Index the folder",
                    text: "Click Confirm. CodeBud walks your project, splits files into chunks, embeds each chunk, and stores the vectors in memory. Large projects may take a few minutes.")

            DocStep(number: "4", title: "Ask questions",
                    text: "Once indexed, your questions are matched against the most relevant code chunks and sent to the model with that context. The mode badge will show RAG MODE.")

            DocNote(text: "The index is stored in memory and cleared when you quit the app. Re-index after making significant changes to your codebase.")
        }
    }

    // MARK: - Models

    private var modelsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DocParagraph(text: "The Models tab shows all Ollama models installed on your system and lets you manage them.")

            DocItem(title: "Installed models",
                    text: "Lists every model pulled via Ollama. Shows real size and parameter count fetched from the Ollama API.")

            DocItem(title: "Setting the active model",
                    text: "Click the play button on any model row to make it active. The active model is used for all chat and RAG queries. You can also switch models from the sidebar picker or the Settings tab.")

            DocItem(title: "Model Store",
                    text: "Click \"Model Store\" to browse curated models. Click Install to pull a model directly — a progress bar shows download progress.")

            DocItem(title: "Deleting models",
                    text: "Click the trash icon on any model row to delete it from your system.")

            DocNote(text: "Recommended setup: install nomic-embed-text for indexing, and qwen2.5-coder:3b or llama3 for chat.")
        }
    }

    // MARK: - Settings

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DocParagraph(text: "The Settings tab lets you personalise CodeBud.")

            DocItem(title: "Display name",
                    text: "Set your name and it appears in the sidebar and chat bubbles across the whole app instantly.")

            DocItem(title: "Theme",
                    text: "Switch between Dark, Light, and System themes. The change applies immediately — no restart needed.")

            DocItem(title: "Active model",
                    text: "Select which installed model to use for chat. Same as the sidebar picker and the Models tab — all three stay in sync.")
        }
    }
}

// MARK: - Doc components

private struct DocParagraph: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color.cbTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct DocStep: View {
    let number: String
    let title: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color.cbAccent).frame(width: 24, height: 24)
                Text(number).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(Color.cbTextPrimary)
                Text(text).font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct DocItem: View {
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(Color.cbTextPrimary)
            Text(text).font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cbCard).cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cbBorder, lineWidth: 1))
    }
}

private struct DocNote: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color.cbAccent).font(.system(size: 13))
            Text(text).font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.cbAccent.opacity(0.08)).cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cbAccent.opacity(0.2), lineWidth: 1))
    }
}
