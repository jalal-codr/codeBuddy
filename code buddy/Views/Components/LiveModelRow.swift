//
//  LiveModelRow.swift
//  code buddy
//

import SwiftUI

struct LiveModelRow: View {
    let model: OllamaModel
    let isCurrent: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.cbBackground).frame(width: 32, height: 32)
                Image(systemName: model.icon)
                    .font(.system(size: 13)).foregroundColor(Color.cbTextSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.cbTextPrimary)
                    if isCurrent {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.cbAccent)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.cbAccent.opacity(0.15)).cornerRadius(3)
                    }
                }
                Text(model.name).font(.system(size: 11)).foregroundColor(Color.cbTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(String(format: "%.1f GB", model.sizeGB))
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color.cbTextPrimary)
                Text("SIZE").font(.system(size: 9)).foregroundColor(Color.cbTextSecondary).tracking(0.5)
            }
            .frame(width: 60)

            VStack(alignment: .trailing, spacing: 1) {
                Text(model.paramLabel)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color.cbTextPrimary)
                Text("PARAMS").font(.system(size: 9)).foregroundColor(Color.cbTextSecondary).tracking(0.5)
            }
            .frame(width: 70)

            // Select button
            Button(action: onSelect) {
                Image(systemName: isCurrent ? "pause.fill" : "play.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isCurrent ? .white : Color.cbTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(isCurrent ? Color.cbAccent : Color.cbCard).cornerRadius(6)
                    .overlay(isCurrent ? nil : RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash").font(.system(size: 11))
                    .foregroundColor(Color.cbTextMuted).frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(isCurrent ? Color.cbCard.opacity(0.8) : Color.cbSurface.opacity(0.4))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(isCurrent ? Color.cbAccent.opacity(0.3) : Color.cbBorder, lineWidth: 1))
    }
}
