//
//  AppearanceOption.swift
//  code buddy
//

import SwiftUI

struct AppearanceOption: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : Color.cbTextSecondary)
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color.cbTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.cbAccent : Color.cbBackground)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.cbAccent : Color.cbBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
