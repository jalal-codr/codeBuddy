//
//  SidebarView.swift
//  code buddy
//

import SwiftUI

enum SidebarTab: String, CaseIterable {
    case setup    = "Setup"
    case models   = "Models"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .setup:    return "display"
        case .models:   return "cpu"
        case .settings: return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    @State private var showDocs: Bool = false
    @AppStorage("username") private var username: String = ""
    @ObservedObject private var modelManager = OllamaModelManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
            navItems
            Spacer()
            modelPicker
            footerLinks
        }
        .frame(width: 200)
        .background(Color.cbSurface)
        .sheet(isPresented: $showDocs) {
            DocsSheet(isPresented: $showDocs)
        }
    }

    // MARK: - Brand

    private var brandHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cbAccent)
                    .frame(width: 36, height: 36)
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("CodeBud")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.cbTextPrimary)
                Text(username.isEmpty ? "V1.0.4" : username)
                    .font(.system(size: 10))
                    .foregroundColor(Color.cbTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    // MARK: - Nav

    private var navItems: some View {
        VStack(spacing: 2) {
            ForEach(SidebarTab.allCases, id: \.self) { tab in
                SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Model quick-switcher

    private var modelPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACTIVE MODEL")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color.cbTextMuted)
                .tracking(0.8)
                .padding(.horizontal, 18)

            if modelManager.installedModels.isEmpty {
                Text("No models installed")
                    .font(.system(size: 11))
                    .foregroundColor(Color.cbTextMuted)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
            } else {
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
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 11))
                            .foregroundColor(Color.cbAccent)
                        Text(activeDisplayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.cbTextPrimary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(Color.cbTextMuted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cbCard)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    private var activeDisplayName: String {
        modelManager.installedModels
            .first { $0.name == modelManager.activeModelName }?
            .displayName
            ?? modelManager.activeModelName
                .replacingOccurrences(of: ":latest", with: "")
                .prefix(18).description
    }

    // MARK: - Footer

    private var footerLinks: some View {
        VStack(spacing: 2) {
            Button(action: { showDocs = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 13))
                        .foregroundColor(Color.cbTextSecondary)
                        .frame(width: 16)
                    Text("Docs")
                        .font(.system(size: 13))
                        .foregroundColor(Color.cbTextSecondary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Button(action: {
                if let url = URL(string: "https://buymeacoffee.com/jallall") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.cbAccent)
                        .frame(width: 16)
                    Text("Donate")
                        .font(.system(size: 13))
                        .foregroundColor(Color.cbAccent)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Sidebar Item

struct SidebarItem: View {
    let tab: SidebarTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : Color.cbTextSecondary)
                    .frame(width: 16)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .white : Color.cbTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.cbAccent : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct SidebarLinkItem: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color.cbTextSecondary)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.cbTextSecondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}
