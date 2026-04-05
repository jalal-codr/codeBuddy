//
//  ActiveModelCard.swift
//  code buddy
//

import SwiftUI

struct ActiveModelCard: View {
    let modelName: String
    let modelDescription: String
    let isActive: Bool

    @State private var showModelPicker = false
    @State private var showModelSettings = false
    @ObservedObject private var modelManager = OllamaModelManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTIVE ENVIRONMENT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.cbTextSecondary).tracking(0.8)
                    Text(modelName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.cbTextPrimary)
                }
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(isActive ? Color.cbGreen : Color.cbTextMuted)
                        .frame(width: 7, height: 7)
                    Text(isActive ? "ACTIVE" : "NONE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.cbTextPrimary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.cbBackground).cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cbBorder, lineWidth: 1))
            }

            Text(modelDescription)
                .font(.system(size: 13))
                .foregroundColor(Color.cbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                // Change Model — opens inline picker
                Menu {
                    ForEach(modelManager.installedModels) { model in
                        Button(action: { modelManager.setActive(model) }) {
                            HStack {
                                Text(model.displayName)
                                if model.name == modelManager.activeModelName {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Divider()
                    Button(action: { showModelPicker = true }) {
                        Label("Browse Model Store", systemImage: "arrow.down.circle")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.2.squarepath").font(.system(size: 12))
                        Text("Change Model").font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.cbAccent).foregroundColor(.white).cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Model Settings — shows detail popover
                Button(action: { showModelSettings.toggle() }) {
                    Text("Model Settings")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.cbTextPrimary)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.cbCard).cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showModelSettings, arrowEdge: .bottom) {
                    ModelSettingsPopover()
                }
            }
        }
        .padding(20)
        .background(Color.cbCard).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showModelPicker) {
            ModelStoreSheet(isPresented: $showModelPicker)
                .environmentObject(modelManager)
        }
    }
}

// MARK: - Model Settings Popover

struct ModelSettingsPopover: View {
    @ObservedObject private var manager = OllamaModelManager.shared
    @State private var temperature: Double = 0.7
    @State private var contextLength: Double = 2048

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Settings")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.cbTextPrimary)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Temperature").font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                    Spacer()
                    Text(String(format: "%.1f", temperature))
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color.cbAccent)
                }
                Slider(value: $temperature, in: 0...2, step: 0.1)
                    .tint(Color.cbAccent)
                Text("Higher = more creative. Lower = more focused.")
                    .font(.system(size: 10)).foregroundColor(Color.cbTextMuted)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Context Length").font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                    Spacer()
                    Text("\(Int(contextLength)) tokens")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color.cbAccent)
                }
                Slider(value: $contextLength, in: 512...8192, step: 512)
                    .tint(Color.cbAccent)
                Text("How much conversation history the model sees.")
                    .font(.system(size: 10)).foregroundColor(Color.cbTextMuted)
            }

            if let model = manager.installedModels.first(where: { $0.name == manager.activeModelName }) {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT MODEL").font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.cbTextMuted).tracking(0.8)
                    Text(model.displayName).font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.cbTextPrimary)
                    Text("\(model.paramLabel) · \(String(format: "%.1f", model.sizeGB)) GB · \(model.family)")
                        .font(.system(size: 11)).foregroundColor(Color.cbTextSecondary)
                }
            }
        }
        .padding(20)
        .frame(width: 280)
        .background(Color.cbSurface)
    }
}
