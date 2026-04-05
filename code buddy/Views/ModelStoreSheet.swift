//
//  ModelStoreSheet.swift
//  code buddy
//

import SwiftUI

struct ModelStoreSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var models: OllamaModelManager
    @State private var searchText: String = ""

    private var filtered: [CatalogModel] {
        guard !searchText.isEmpty else { return models.catalog }
        return models.catalog.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.family.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Model Store")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.cbTextPrimary)
                    Text("Browse and install models from Ollama")
                        .font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                }
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

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13)).foregroundColor(Color.cbTextMuted)
                TextField("Search models…", text: $searchText)
                    .font(.system(size: 13)).foregroundColor(Color.cbTextPrimary)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(Color.cbBackground).cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cbBorder, lineWidth: 1))
            .padding(16)
            .background(Color.cbSurface)
            .overlay(Divider().background(Color.cbBorder), alignment: .bottom)

            // Pull progress
            if models.isPulling {
                PullProgressBanner(
                    modelName: models.pullingModel,
                    status: models.pullStatus,
                    progress: models.pullProgress
                )
                .padding(16)
                .background(Color.cbSurface)
                .overlay(Divider().background(Color.cbBorder), alignment: .bottom)
            }

            // Model list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filtered) { item in
                        CatalogRow(item: item, isInstalled: isInstalled(item), isPulling: models.isPulling && models.pullingModel == item.name) {
                            models.pull(modelName: item.name)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.cbBackground)
        }
        .frame(width: 620, height: 520)
        .background(Color.cbBackground)
    }

    private func isInstalled(_ item: CatalogModel) -> Bool {
        models.installedModels.contains { $0.name == item.name || $0.name == "\(item.name):latest" }
    }
}

private struct CatalogRow: View {
    let item: CatalogModel
    let isInstalled: Bool
    let isPulling: Bool
    let onInstall: () -> Void

    var icon: String {
        switch item.family.lowercased() {
        case let f where f.contains("llama"):   return "hare.fill"
        case let f where f.contains("mistral"): return "wind"
        case let f where f.contains("phi"):     return "bolt.fill"
        case let f where f.contains("gemma"):   return "sparkles"
        case let f where f.contains("qwen"):    return "globe.asia.australia.fill"
        case let f where f.contains("nomic"):   return "waveform"
        default:                                return "cpu"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cbCard).frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16)).foregroundColor(Color.cbAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.cbTextPrimary)
                    if item.name == "nomic-embed-text" {
                        Text("REQUIRED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15)).cornerRadius(3)
                    }
                }
                Text(item.description)
                    .font(.system(size: 11)).foregroundColor(Color.cbTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.sizeLabel)
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Color.cbTextPrimary)
                Text(item.paramLabel)
                    .font(.system(size: 10)).foregroundColor(Color.cbTextSecondary)
            }
            .frame(width: 60)

            // Install / installed button
            if isInstalled {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                    Text("Installed").font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color.cbGreen)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.cbGreen.opacity(0.12)).cornerRadius(6)
            } else if isPulling {
                ProgressView().scaleEffect(0.7).frame(width: 70)
            } else {
                Button(action: onInstall) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle").font(.system(size: 11))
                        Text("Install").font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.cbAccent).cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.cbCard).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))
    }
}
