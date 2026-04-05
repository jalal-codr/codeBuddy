//
//  BackendManager.swift
//  code buddy
//
//  Pure Swift RAG engine — no Go binary required.
//  Talks directly to the Ollama REST API:
//    POST /api/embeddings  — embed text chunks + questions
//    POST /api/generate    — generate answers from RAG prompt
//
//  Pipeline:
//    index(path)  → walk files → chunk → embed → store in memory
//    ask(question) → embed question → cosine TopK → build prompt → generate
//

import Foundation
import Combine
import CryptoKit

// MARK: - Chunk stored in memory

private struct Chunk {
    let id: String
    let filePath: String
    let content: String
    var vector: [Float] = []
}

// MARK: - BackendManager

final class BackendManager: ObservableObject {

    static let shared = BackendManager()

    private let ollamaBase    = "http://127.0.0.1:11434"
    private let embedModel    = "nomic-embed-text"
    private let chunkLines    = 30
    private let chunkMaxChars = 2000
    private let topK          = 3

    // MARK: - Published state
    @Published var isIndexing: Bool   = false
    @Published var indexStatus: String = ""
    @Published var isAsking: Bool     = false
    @Published var lastError: String  = ""

    // Active generation task — kept so we can cancel it
    private var activeTask: URLSessionDataTask?

    // In-memory vector store (keyed by chunk id)
    private var store: [String: Chunk] = [:]

    var hasIndex: Bool { !store.isEmpty }

    // MARK: - Cancel in-flight generation

    func cancelGeneration() {
        activeTask?.cancel()
        activeTask = nil
        DispatchQueue.main.async {
            self.isAsking = false
        }
    }

    // Skipped dirs/extensions (mirrors the Go indexer)
    private let skipDirs: Set<String> = [
        ".git", ".svn", "node_modules", "vendor", ".build",
        "DerivedData", ".gradle", "build", "dist", "__pycache__"
    ]
    private let skipExts: Set<String> = [
        "png","jpg","jpeg","gif","svg","ico","pdf","zip","tar","gz",
        "exe","bin","so","dylib","a","o","class","jar","war",
        "mp3","mp4","mov","avi","woff","woff2","ttf","eot"
    ]

    // MARK: - Index

    func index(path: String, completion: @escaping (Bool) -> Void) {
        guard OllamaManager.shared.isPortOpen() else {
            lastError = "Ollama is not running."
            completion(false)
            return
        }

        isIndexing = true
        indexStatus = "Scanning files…"
        lastError = ""
        store.removeAll()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let files = self.walkDirectory(path)
            DispatchQueue.main.async { self.indexStatus = "Found \(files.count) files" }

            var indexed = 0
            for file in files {
                let chunks = self.chunkFile(file)
                for chunk in chunks {
                    DispatchQueue.main.async {
                        self.indexStatus = "Embedding \(URL(fileURLWithPath: file).lastPathComponent)…"
                    }
                    if let vec = self.embed(text: chunk.content) {
                        var c = chunk
                        c.vector = vec
                        self.store[c.id] = c
                    }
                }
                indexed += 1
            }

            DispatchQueue.main.async {
                self.isIndexing = false
                self.indexStatus = "Indexed \(indexed) files, \(self.store.count) chunks"
                completion(true)
            }
        }
    }

    // MARK: - Direct chat (no RAG, no folder needed)

    func chat(message: String, completion: @escaping (String?) -> Void) {
        guard OllamaManager.shared.isPortOpen() else {
            lastError = "Ollama is not running."
            completion(nil)
            return
        }

        isAsking = true
        lastError = ""

        let name = UserDefaults.standard.string(forKey: "username") ?? ""
        let systemPrefix = name.isEmpty
            ? "You are CodeBud, a helpful coding assistant.\n\n"
            : "You are CodeBud, a helpful coding assistant. The user's name is \(name). Address them by name when appropriate.\n\n"
        let fullPrompt = systemPrefix + message

        let model = OllamaModelManager.shared.activeModelName.isEmpty
            ? "qwen2.5-coder:3b"
            : OllamaModelManager.shared.activeModelName

        generate(prompt: fullPrompt, model: model) { [weak self] answer in
            DispatchQueue.main.async {
                self?.isAsking = false
                if let answer { completion(answer) }
                else { self?.lastError = "No response from model"; completion(nil) }
            }
        }
    }

    // MARK: - Ask

    func ask(question: String, completion: @escaping (String?) -> Void) {
        guard OllamaManager.shared.isPortOpen() else {
            lastError = "Ollama is not running."
            completion(nil)
            return
        }
        guard !store.isEmpty else {
            lastError = "No index found. Please index a folder first."
            completion(nil)
            return
        }

        isAsking = true
        lastError = ""

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            guard let qVec = self.embed(text: question) else {
                DispatchQueue.main.async {
                    self.isAsking = false
                    self.lastError = "Failed to embed question"
                    completion(nil)
                }
                return
            }

            let topChunks = self.topK(query: qVec, k: self.topK)
            let prompt    = self.buildPrompt(question: question, chunks: topChunks)
            let model     = OllamaModelManager.shared.activeModelName.isEmpty
                ? "qwen2.5-coder:3b"
                : OllamaModelManager.shared.activeModelName

            self.generate(prompt: prompt, model: model) { answer in
                DispatchQueue.main.async {
                    self.isAsking = false
                    if let answer { completion(answer) }
                    else { self.lastError = "No response from model"; completion(nil) }
                }
            }
        }
    }

    // MARK: - File walking

    private func walkDirectory(_ root: String) -> [String] {
        var results: [String] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: root),
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let url as URL in enumerator {
            // Skip directories in skip list
            if url.hasDirectoryPath {
                if skipDirs.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            let ext = url.pathExtension.lowercased()
            guard !skipExts.contains(ext) else { continue }

            // Skip files > 1 MB
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            guard size < 1_048_576 else { continue }

            results.append(url.path)
        }
        return results
    }

    // MARK: - Chunking (30 lines / 2000 chars, mirrors Go chunker)

    private func chunkFile(_ path: String) -> [Chunk] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return [] }
        let lines = content.components(separatedBy: "\n")
        var chunks: [Chunk] = []
        var i = 0

        while i < lines.count {
            var block = ""
            var j = i
            while j < lines.count && (j - i) < chunkLines && block.count < chunkMaxChars {
                block += lines[j] + "\n"
                j += 1
            }
            let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { i = j; continue }

            let id = sha256("\(path):\(i)")
            chunks.append(Chunk(id: id, filePath: path, content: trimmed))
            i = j
        }
        return chunks
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    // MARK: - Embed (synchronous, called from background thread)

    private func embed(text: String) -> [Float]? {
        guard let url = URL(string: "\(ollamaBase)/api/embeddings") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": embedModel,
            "prompt": text
        ])

        var result: [Float]?
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            defer { sem.signal() }
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let raw = obj["embedding"] as? [Double] else { return }
            result = raw.map { Float($0) }
        }.resume()
        sem.wait()
        return result
    }

    // MARK: - Cosine similarity TopK

    private func topK(query: [Float], k: Int) -> [Chunk] {
        store.values
            .map { ($0, cosine(query, $0.vector)) }
            .sorted { $0.1 > $1.1 }
            .prefix(k)
            .map { $0.0 }
    }

    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0; var na: Float = 0; var nb: Float = 0
        for i in 0..<a.count { dot += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
        let denom = sqrt(na) * sqrt(nb)
        return denom > 0 ? dot / denom : 0
    }

    // MARK: - RAG prompt (mirrors Go llm.go)

    private func buildPrompt(question: String, chunks: [Chunk]) -> String {
        let name = UserDefaults.standard.string(forKey: "username") ?? ""
        let greeting = name.isEmpty ? "" : "The user's name is \(name). Address them by name when appropriate.\n"
        var s = "You are a senior engineer reviewing a codebase.\n"
        s += greeting
        s += "Answer ONLY using the context below.\n"
        s += "If the answer is not in the context, say 'I don't know'.\n"
        s += "Never reveal file contents verbatim.\n\n"
        s += "--- CONTEXT ---\n"
        for c in chunks { s += "// \(c.filePath)\n\(c.content)\n\n" }
        s += "--- QUESTION ---\n\(question)\n--- END ---\n"
        return s
    }

    // MARK: - Generate (async, stores task for cancellation)

    private func generate(prompt: String, model: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(ollamaBase)/api/generate") else { completion(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 600
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model,
            "prompt": prompt,
            "stream": false
        ])

        let task = URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            self?.activeTask = nil
            // Cancelled — don't call completion
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                return
            }
            guard let data, error == nil,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let response = obj["response"] as? String else {
                completion(nil)
                return
            }
            completion(response.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        activeTask = task
        task.resume()
    }
}
