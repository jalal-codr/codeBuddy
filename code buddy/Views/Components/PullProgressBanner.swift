//
//  PullProgressBanner.swift
//  code buddy
//

import SwiftUI

struct PullProgressBanner: View {
    let modelName: String
    let status: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.7)
                Text("Installing \(modelName)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.cbTextPrimary)
                Spacer()
                Text(status).font(.system(size: 11)).foregroundColor(Color.cbTextSecondary)
                    .lineLimit(1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.cbBorder).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(Color.cbAccent)
                        .frame(width: geo.size.width * max(progress, 0.02), height: 4)
                        .animation(.linear(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .background(Color.cbCard).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cbAccent.opacity(0.3), lineWidth: 1))
    }
}
