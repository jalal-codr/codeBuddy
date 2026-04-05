//
//  ChatMessage.swift
//  code buddy
//

import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let isUser: Bool
    let text: String
    let time: String
    let isThinking: Bool   // shows loader instead of text

    init(isUser: Bool, text: String, time: String, isThinking: Bool = false) {
        self.id         = UUID()
        self.isUser     = isUser
        self.text       = text
        self.time       = time
        self.isThinking = isThinking
    }
}

func currentTime() -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: Date())
}
