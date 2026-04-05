//
//  OllamaModelManager.swift
//  code buddy
//
//  Talks to the Ollama REST API to list, select, and pull models.
//  GET  /api/tags          — list installed models
//  POST /api/pull          — pull (install) a model, streams progress
//  POST /api/delete        — delete a model
//

import Foundation
import Combine

// MARK: - Data types

struct OllamaModel: Identifiable, Equatable {
    let id: String          // same as name
    let name: String        // e.g. "llama3:latest"
    let displayName: String // e.g. "Llama 3"
    let sizeGB: Double
    let paramLabel: String  // e.g. "8B"
    let family: String      // e.g. "llama"

    var icon: String {
        switch family.lowercased() {
        case let f where f.contains("llama"):   return "hare.fill"
        case let f where f.contains("mistral"): return "wind"
        case let f where f.contains("phi"):     return "bolt.fill"
        case let f where f.contains("gemma"):   return "sparkles"
        case let f where f.contains("qwen"):    return "globe.asia.australia.fill"
        default:                                return "cpu"
        }
    }
}

struct CatalogModel: Identifiable {
    let id: String
    let name: String          // pull tag e.g. "llama3"
    let displayName: String
    let description: String
    let sizeLabel: String
    let paramLabel: String
    let family: String
}

// MARK: - Manager

final class OllamaModelManager: ObservableObject {

    static let shared = OllamaModelManager()

    private let base = "http://127.0.0.1:11434"

    @Published var installedModels: [OllamaModel] = []
    @Published var activeModelName: String = ""       // tag used by devcompanion
    @Published var isLoading: Bool = false

    // Pull progress
    @Published var pullingModel: String = ""
    @Published var pullProgress: Double = 0           // 0-1
    @Published var pullStatus: String = ""
    @Published var isPulling: Bool = false

    @Published var errorMessage: String = ""

    // MARK: - Catalog of models users can install
    let catalog: [CatalogModel] = [
        CatalogModel(id: "llama3",            name: "llama3",            displayName: "Llama 3 8B",        description: "Meta's flagship open model. Great all-rounder for code and chat.",          sizeLabel: "4.7 GB",  paramLabel: "8B",   family: "llama"),
        CatalogModel(id: "llama3:70b",        name: "llama3:70b",        displayName: "Llama 3 70B",       description: "Larger Llama 3 — better reasoning, needs 40 GB+ RAM.",                    sizeLabel: "40 GB",   paramLabel: "70B",  family: "llama"),
        CatalogModel(id: "mistral",           name: "mistral",           displayName: "Mistral 7B",        description: "Fast, versatile coder. Excellent instruction following.",                  sizeLabel: "4.1 GB",  paramLabel: "7B",   family: "mistral"),
        CatalogModel(id: "codellama",         name: "codellama",         displayName: "Code Llama 7B",     description: "Meta's code-focused model. Strong at completion and explanation.",         sizeLabel: "3.8 GB",  paramLabel: "7B",   family: "llama"),
        CatalogModel(id: "phi3",              name: "phi3",              displayName: "Phi-3 Mini",        description: "Microsoft's tiny but capable model. Low RAM, fast inference.",             sizeLabel: "2.3 GB",  paramLabel: "3.8B", family: "phi"),
        CatalogModel(id: "gemma2",            name: "gemma2",            displayName: "Gemma 2 9B",        description: "Google's Gemma 2. Strong at reasoning and code tasks.",                   sizeLabel: "5.4 GB",  paramLabel: "9B",   family: "gemma"),
        CatalogModel(id: "qwen2.5-coder:3b",  name: "qwen2.5-coder:3b",  displayName: "Qwen 2.5 Coder 3B", description: "Alibaba's code-specialist. Default model for devcompanion RAG.",           sizeLabel: "1.9 GB",  paramLabel: "3B",   family: "qwen"),
        CatalogModel(id: "qwen2.5-coder:7b",  name: "qwen2.5-coder:7b",  displayName: "Qwen 2.5 Coder 7B", description: "Larger Qwen coder — better at complex multi-file reasoning.",             sizeLabel: "4.7 GB",  paramLabel: "7B",   family: "qwen"),
        CatalogModel(id: "nomic-embed-text",  name: "nomic-embed-text",  displayName: "Nomic Embed Text",  description: "Embedding model required by devcompanion for indexing. Install this first.", sizeLabel: "274 MB",  paramLabel: "—",    family: "nomic"),
        CatalogModel(id: "deepseek-coder",    name: "deepseek-coder",    displayName: "DeepSeek Coder 6.7B", description: "Strong open-source code model from DeepSeek.",                         sizeLabel: "3.8 GB",  paramLabel: "6.7B", family: "deepseek"),
    ]

    // MARK: - Fetch installed models

    func fetchInstalled() {
        guard OllamaManager.shared.isPortOpen() else {
            errorMessage = "Ollama not running"
            return
        }
        isLoading = true
        errorMessage = ""

        guard let url = URL(string: "\(base)/api/tags") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let data else { return }
                self?.parseInstalledModels(data)
            }
        }.resume()
    }

    private func parseInstalledModels(_ data: Data) {
        struct TagsResponse: Decodable {
            struct ModelEntry: Decodable {
                let name: String
                let size: Int64?
                let details: Details?
                struct Details: Decodable {
                    let family: String?
                    let parameter_size: String?
                }
            }
            let models: [ModelEntry]
        }

        guard let resp = try? JSONDecoder().decode(TagsResponse.self, from: data) else { return }

        installedModels = resp.models.map { entry in
            let sizeGB = Double(entry.size ?? 0) / 1_073_741_824
            let family = entry.details?.family ?? ""
            let params = entry.details?.parameter_size ?? "—"
            let display = entry.name
                .replacingOccurrences(of: ":latest", with: "")
                .split(separator: "/").last.map(String.init) ?? entry.name
            return OllamaModel(
                id: entry.name,
                name: entry.name,
                displayName: display,
                sizeGB: sizeGB,
                paramLabel: params,
                family: family
            )
        }

        // Auto-select first model if none chosen yet
        if activeModelName.isEmpty, let first = installedModels.first {
            activeModelName = first.name
        }
    }

    // MARK: - Set active model

    func setActive(_ model: OllamaModel) {
        activeModelName = model.name
    }

    // MARK: - Pull (install) a model

    func pull(modelName: String) {
        guard OllamaManager.shared.isPortOpen() else {
            errorMessage = "Ollama not running"
            return
        }
        guard !isPulling else { return }

        isPulling = true
        pullingModel = modelName
        pullProgress = 0
        pullStatus = "Starting…"
        errorMessage = ""

        guard let url = URL(string: "\(base)/api/pull") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["name": modelName, "stream": true])

        let task = URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            // streaming handled via delegate — this is fallback
        }

        // Use a streaming approach via URLSession delegate
        let session = URLSession(configuration: .default, delegate: PullStreamDelegate { [weak self] status, completed, total in
            DispatchQueue.main.async {
                self?.pullStatus = status
                if total > 0 { self?.pullProgress = Double(completed) / Double(total) }
            }
        } onDone: { [weak self] success in
            DispatchQueue.main.async {
                self?.isPulling = false
                self?.pullingModel = ""
                self?.pullProgress = 0
                self?.pullStatus = ""
                if success { self?.fetchInstalled() }
                else { self?.errorMessage = "Pull failed for \(modelName)" }
            }
        }, delegateQueue: nil)

        var streamReq = URLRequest(url: url)
        streamReq.httpMethod = "POST"
        streamReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        streamReq.httpBody = try? JSONSerialization.data(withJSONObject: ["name": modelName, "stream": true])
        session.dataTask(with: streamReq).resume()
    }

    // MARK: - Delete a model

    func delete(modelName: String) {
        guard let url = URL(string: "\(base)/api/delete") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["name": modelName])

        URLSession.shared.dataTask(with: req) { [weak self] _, _, _ in
            DispatchQueue.main.async { self?.fetchInstalled() }
        }.resume()
    }
}

// MARK: - Streaming delegate for pull progress

private class PullStreamDelegate: NSObject, URLSessionDataDelegate {
    private var buffer = Data()
    private let onProgress: (String, Int64, Int64) -> Void
    private let onDone: (Bool) -> Void

    init(onProgress: @escaping (String, Int64, Int64) -> Void, onDone: @escaping (Bool) -> Void) {
        self.onProgress = onProgress
        self.onDone = onDone
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        // Each line is a JSON object
        while let range = buffer.range(of: Data([0x0A])) { // newline
            let line = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex...range.lowerBound)
            guard let obj = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else { continue }
            let status    = obj["status"] as? String ?? ""
            let completed = obj["completed"] as? Int64 ?? 0
            let total     = obj["total"] as? Int64 ?? 0
            onProgress(status, completed, total)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onDone(error == nil)
    }
}
