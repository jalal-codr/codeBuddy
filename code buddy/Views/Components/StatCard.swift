//
//  StatCard.swift
//  code buddy
//

import SwiftUI

struct StatCard: View {
    let label: String
    let value: String
    let unit: String
    let progress: Double
    let barColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.cbTextSecondary)
                .tracking(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.cbTextPrimary)
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(Color.cbTextSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.cbBorder)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.cbCard)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbBorder, lineWidth: 1))
    }
}
