//
//  ModelsView.swift
//  code buddy
//

import SwiftUI

struct ModelsView: View {
    @StateObject private var stats   = SystemStatsMonitor()
    @StateObject private var models  = OllamaModelManager.shared
    @State private var isRunInBackground: Bool = true
    @State private var showStore: Bool = false
    @State private var filterFamily: String = "All"

    private var families: [String] {
        let all = models.installedModels.map { $0.family.isEmpty ? "Other" : $0.family.capitalized }
        return ["All"] + Array(Set(all)).sorted()
    }

    private var filteredModels: [OllamaModel] {
        guard filterFamily != "All" else { return models.installedModels }
        return models.installedModels.filter {
            ($0.family.isEmpty ? "Other" : $0.family.capitalized) == filterFamily
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Breadcrumb
                HStack(spacing: 6) {
                    Text("Models").font(.system(size: 12)).foregroundColor(Color.cbTextSecondary)
                    Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(Color.cbTextMuted)
                    Text("Model Management").font(.system(size: 12)).foregroundColor(Color.cbTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                // Active model + service status
                HStack(alignment: .top, spacing: 12) {
                    ActiveModelCard(
                        modelName: activeModel?.displayName ?? "No model selected",
                        modelDescription: activeModel.map {
                            "\($0.paramLabel) · \(String(format: "%.1f", $0.sizeGB)) GB · \($0.family.capitalized)"
                        } ?? "Go to Model Store to install a model",
                        isActive: activeModel != nil
                    )
                    ServiceStatusPanel(isRunInBackground: $isRunInBackground)
                }
                .padding(.horizontal, 24)

                // Pull progress
                if models.isPulling {
                    PullProgressBanner(modelName: models.pullingModel,
                                       status: models.pullStatus,
                                       progress: models.pullProgress)
                    .padding(.horizontal, 24)
                }

                // Error
                if !models.errorMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(models.errorMessage).font(.system(size: 12)).foregroundColor(.orange)
                        Spacer()
                        Button(action: { models.errorMessage = "" }) {
                            Image(systemName: "xmark").font(.system(size: 10))
                                .foregroundColor(Color.cbTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12).background(Color.orange.opacity(0.08)).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 24)
                }

                // Library header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Installed Models")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.cbTextPrimary)
                        if !models.installedModels.isEmpty {
                            Text("\(models.installedModels.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.cbAccent)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Color.cbAccent.opacity(0.1)).cornerRadius(10)
                        }
                        Spacer()

                        // Filter by family
                        if families.count > 2 {
                            Menu {
                                ForEach(families, id: \.self) { family in
                                    Button(action: { filterFamily = family }) {
                                        HStack {
                                            Text(family)
                                            if filterFamily == family {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "line.3.horizontal.decrease")
                                        .font(.system(size: 12))
                                    Text(filterFamily == "All" ? "Filter" : filterFamily)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(filterFamily == "All" ? Color.cbTextSecondary : Color.cbAccent)
                                .frame(height: 32)
                                .padding(.horizontal, 10)
                                .background(Color.cbCard).cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(filterFamily == "All" ? Color.cbBorder : Color.cbAccent.opacity(0.4), lineWidth: 1))
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }

                        // Refresh
                        Button(action: { models.fetchInstalled() }) {
                            Image(systemName: models.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                                .font(.system(size: 13))
                                .foregroundColor(Color.cbTextSecondary)
                                .rotationEffect(models.isLoading ? .degrees(360) : .zero)
                                .animation(models.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: models.isLoading)
                                .frame(width: 32, height: 32)
                                .background(Color.cbCard).cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        // Model Store
                        Button(action: { showStore = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle").font(.system(size: 13))
                                Text("Model Store").font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Color.cbAccent).foregroundColor(.white).cornerRadius(6)
                            .shadow(color: Color.cbAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }

                    // Model list
                    if models.isLoading {
                        HStack { Spacer(); ProgressView().tint(Color.cbAccent); Spacer() }.padding()
                    } else if filteredModels.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredModels) { model in
                                LiveModelRow(
                                    model: model,
                                    isCurrent: model.name == models.activeModelName,
                                    onSelect: { models.setActive(model) },
                                    onDelete: { models.delete(modelName: model.name) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Stats
                HStack(spacing: 12) {
                    StatCard(label: "MEMORY USAGE",
                             value: String(format: "%.1f", stats.memoryUsedGB),
                             unit: "/ \(String(format: "%.0f", stats.memoryTotalGB)) GB",
                             progress: stats.memoryFraction, barColor: Color.cbAccent)
                    StatCard(label: "CPU LOAD",
                             value: String(format: "%.0f", stats.cpuPercent),
                             unit: "%", progress: stats.cpuUsageFraction, barColor: .orange)
                    StatCard(label: "DISK USAGE",
                             value: String(format: "%.0f", stats.diskUsedGB),
                             unit: "/ \(String(format: "%.0f", stats.diskTotalGB)) GB",
                             progress: stats.diskFraction, barColor: Color.cbAccent)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
        .background(Color.cbBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { stats.start(); models.fetchInstalled() }
        .onDisappear { stats.stop() }
        .sheet(isPresented: $showStore) {
            ModelStoreSheet(isPresented: $showStore)
                .environmentObject(models)
        }
    }

    private var activeModel: OllamaModel? {
        models.installedModels.first { $0.name == models.activeModelName }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: filterFamily == "All" ? "tray" : "line.3.horizontal.decrease")
                .font(.system(size: 28)).foregroundColor(Color.cbTextMuted)
            Text(filterFamily == "All" ? "No models installed" : "No \(filterFamily) models")
                .font(.system(size: 13, weight: .medium)).foregroundColor(Color.cbTextSecondary)
            if filterFamily == "All" {
                Button(action: { showStore = true }) {
                    Text("Open Model Store")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.cbAccent).cornerRadius(6)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { filterFamily = "All" }) {
                    Text("Clear filter")
                        .font(.system(size: 12)).foregroundColor(Color.cbAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity).padding(32)
        .background(Color.cbCard).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))
    }
}
