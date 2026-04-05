//
//  SectionHeader.swift
//  code buddy
//

import SwiftUI

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Color.cbAccent)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.cbTextSecondary)
                .tracking(0.8)
        }
    }
}
