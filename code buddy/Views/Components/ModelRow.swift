//
//  ModelRow.swift
//  code buddy
//

import SwiftUI

struct ModelRow: View {
    let model: LocalModel
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.cbBackground)
                    .frame(width: 32, height: 32)
                Image(systemName: model.icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color.cbTextSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.cbTextPrimary)
                    if isCurrent {
                        Text("CURRENT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.cbAccent)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.cbAccent.opacity(0.15))
                            .cornerRadius(3)
                    }
                }
                Text(model.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color.cbTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(model.diskSpace)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.cbTextPrimary)
                Text("DISK SPACE")
                    .font(.system(size: 9))
                    .foregroundColor(Color.cbTextSecondary).tracking(0.5)
            }
            .frame(width: 60)

            VStack(alignment: .trailing, spacing: 1) {
                Text(model.quantization)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.cbTextPrimary)
                Text("QUANTIZATION")
                    .font(.system(size: 9))
                    .foregroundColor(Color.cbTextSecondary).tracking(0.5)
            }
            .frame(width: 90)

            if isCurrent {
                Button(action: {}) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10)).foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.cbAccent).cornerRadius(6)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {}) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10)).foregroundColor(Color.cbTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.cbCard).cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cbBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Button(action: {}) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(Color.cbTextMuted)
                    .frame(width: 28, height: 28)
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
