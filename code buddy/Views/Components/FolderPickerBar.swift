//
//  FolderPickerBar.swift
//  code buddy
//

import SwiftUI

struct FolderPickerBar: View {
    @Binding var pendingPath: String
    let submittedPath: String?
    let onBrowse: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROJECT FOLDER")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.cbTextSecondary).tracking(0.8)

            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundColor(Color.cbTextMuted)
                    Text(pendingPath.isEmpty ? "No folder selected" : pendingPath)
                        .font(.system(size: 12))
                        .foregroundColor(pendingPath.isEmpty ? Color.cbTextMuted : Color.cbTextPrimary)
                        .lineLimit(1).truncationMode(.middle)
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cbBackground).cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))

                Button(action: onBrowse) {
                    Text("Browse")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.cbTextPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.cbCard).cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle").font(.system(size: 12))
                        Text("Confirm").font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(pendingPath.isEmpty ? Color.cbAccent.opacity(0.4) : Color.cbAccent)
                    .foregroundColor(.white).cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(pendingPath.isEmpty)
            }

            if let path = submittedPath {
                HStack(spacing: 6) {
                    Circle().fill(Color.cbGreen).frame(width: 6, height: 6)
                    Text("ACTIVE:").font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.cbTextSecondary).tracking(0.6)
                    Text(path).font(.system(size: 11))
                        .foregroundColor(Color.cbGreen)
                        .lineLimit(1).truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.cbSurface)
        .overlay(Divider().background(Color.cbBorder), alignment: .bottom)
    }
}
