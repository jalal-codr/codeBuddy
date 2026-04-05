//
//  SettingsView.swift
//  code buddy
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("username") private var username: String = ""
    @State private var editingName: String = ""
    @State private var nameSaved: Bool = false
    @ObservedObject private var modelManager = OllamaModelManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Breadcrumb
                HStack(spacing: 6) {
                    Image(systemName: "gearshape").font(.system(size: 12))
                        .foregroundColor(Color.cbTextSecondary)
                    Text("Settings").font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.cbTextSecondary).tracking(1)
                    Image(systemName: "chevron.right").font(.system(size: 10))
                        .foregroundColor(Color.cbTextMuted)
                    Text("Preferences").font(.system(size: 12))
                        .foregroundColor(Color.cbTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                profileSection.padding(.horizontal, 24)
                modelSection.padding(.horizontal, 24)
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .background(Color.cbBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { editingName = "" }
    }

    // MARK: - Profile

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "person.circle", title: "PROFILE")
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name").font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.cbTextSecondary)

                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.cbAccent.opacity(0.2)).frame(width: 36, height: 36)
                        Text(avatarLetter)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.cbAccent)
                    }

                    TextField(username.isEmpty ? "Enter your name..." : username, text: $editingName)
                        .font(.system(size: 13)).foregroundColor(Color.cbTextPrimary)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.cbBackground).cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))
                        .onSubmit { saveName() }

                    Button(action: saveName) {
                        Text(nameSaved ? "Saved ✓" : "Save")
                            .font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(nameSaved ? Color.cbGreen : (editingName.isEmpty ? Color.cbAccent.opacity(0.4) : Color.cbAccent))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain).disabled(editingName.isEmpty)
                }

                if !username.isEmpty {
                    HStack(spacing: 5) {
                        Circle().fill(Color.cbGreen).frame(width: 5, height: 5)
                        Text("Showing as \"\(username)\" across the app")
                            .font(.system(size: 11))
                            .foregroundColor(Color.cbTextSecondary)
                    }
                }
            }
        }
        .padding(20).background(Color.cbCard).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))
    }

    // MARK: - Model quick-switch

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "cpu", title: "ACTIVE MODEL")
            VStack(alignment: .leading, spacing: 8) {
                Text("Select the model used for chat and RAG queries.")
                    .font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                modelList
            }
        }
        .padding(20).background(Color.cbCard).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))
    }

    @ViewBuilder
    private var modelList: some View {
        if modelManager.installedModels.isEmpty {
            Text("No models installed. Go to Models → Model Store to install one.")
                .font(.system(size: 12)).foregroundColor(Color.cbTextMuted)
        } else {
            VStack(spacing: 6) {
                ForEach(modelManager.installedModels) { model in
                    modelRow(model: model)
                }
            }
        }
    }

    private func modelRow(model: OllamaModel) -> some View {
        let isActive = model.name == modelManager.activeModelName
        return Button(action: { modelManager.setActive(model) }) {
            HStack(spacing: 10) {
                Image(systemName: model.icon)
                    .font(.system(size: 13))
                    .foregroundColor(isActive ? Color.cbAccent : Color.cbTextSecondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.cbTextPrimary)
                    Text("\(model.paramLabel) · \(String(format: "%.1f", model.sizeGB)) GB")
                        .font(.system(size: 10))
                        .foregroundColor(Color.cbTextSecondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.cbAccent)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(isActive ? Color.cbAccent.opacity(0.1) : Color.cbBackground)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.cbAccent.opacity(0.4) : Color.cbBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var avatarLetter: String {
        let src = editingName.isEmpty ? username : editingName
        return src.isEmpty ? "?" : String(src.prefix(1)).uppercased()
    }

    private func saveName() {
        guard !editingName.isEmpty else { return }
        username = editingName
        editingName = ""
        nameSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { nameSaved = false }
    }
}
