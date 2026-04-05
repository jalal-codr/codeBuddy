//
//  Models.swift
//  code buddy
//

import Foundation

struct LocalModel: Identifiable {
    let id: Int
    let name: String
    let subtitle: String
    let description: String
    let diskSpace: String
    let quantization: String
    let icon: String
}

let sampleModels: [LocalModel] = [
    LocalModel(id: 0, name: "Mistral-7B-v0.2", subtitle: "General purpose, versatile coder",
               description: "", diskSpace: "4.1 GB", quantization: "Q4_K_M", icon: "doc.text"),
    LocalModel(id: 1, name: "Phi-3 Mini", subtitle: "High-speed, low resource usage",
               description: "", diskSpace: "2.3 GB", quantization: "F16", icon: "bolt"),
    LocalModel(id: 2, name: "Llama 3", subtitle: "Meta's flagship open model",
               description: "Optimized for high-precision logic and multi-turn conversational coding. Running locally on Apple Silicon.",
               diskSpace: "4.7 GB", quantization: "Q4_0", icon: "cpu"),
]
