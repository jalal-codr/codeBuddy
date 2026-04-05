//
//  OllamaManager.swift
//  code buddy
//

import Foundation
import Darwin

final class OllamaManager: ObservableObject {

    static let shared = OllamaManager()

    @Published var isRunning: Bool = false
    @Published var statusText: String = "Starting…"

    private var process: Process?

    private let ollamaCandidates = [
        "/usr/local/bin/ollama",
        "/opt/homebrew/bin/ollama",
        "/usr/bin/ollama"
    ]

    private var ollamaPath: String? {
        ollamaCandidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    // MARK: - Start

    func start() {
        // Already reachable — nothing to do
        if isPortOpen() {
            DispatchQueue.main.async {
                self.isRunning = true
                self.statusText = "Running v0.18.2"
            }
            return
        }

        guard let path = ollamaPath else {
            DispatchQueue.main.async {
                self.statusText = "ollama not found — install from ollama.com"
            }
            return
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }

            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: path)
            proc.arguments = ["serve"]
            proc.environment = [
                "HOME":         NSHomeDirectory(),
                "PATH":         "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin",
                "OLLAMA_HOST":  "127.0.0.1:11434"   // force IPv4, no IPv6
            ]
            proc.standardOutput = FileHandle.nullDevice
            proc.standardError  = FileHandle.nullDevice

            proc.terminationHandler = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isRunning = false
                    self?.statusText = "Stopped"
                }
            }

            do {
                try proc.run()
                self.process = proc

                // Poll until port is open (up to 10 seconds)
                var ready = false
                for _ in 0..<20 {
                    Thread.sleep(forTimeInterval: 0.5)
                    if self.isPortOpen() { ready = true; break }
                }

                DispatchQueue.main.async {
                    self.isRunning = ready
                    self.statusText = ready ? "Running v0.18.2" : "Started (waiting…)"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusText = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Stop

    func stop() {
        process?.terminate()
        process = nil
        DispatchQueue.main.async {
            self.isRunning = false
            self.statusText = "Stopped"
        }
    }

    // MARK: - Restart

    func restart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.start() }
    }

    // MARK: - TCP port check (IPv4 127.0.0.1:11434)

    func isPortOpen() -> Bool {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        // Set a 1-second timeout on the socket
        var timeout = timeval(tv_sec: 1, tv_usec: 0)
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        var addr = sockaddr_in()
        addr.sin_family      = sa_family_t(AF_INET)
        addr.sin_port        = UInt16(11434).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return result == 0
    }
}
