//
//  ContentView.swift
//  code buddy
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: SidebarTab = .models

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedTab: $selectedTab)
            Divider().background(Color.cbBorder)
            MainContentView(selectedTab: selectedTab)
        }
        .frame(width: 900, height: 660)
        .background(Color.cbBackground)
    }
}

struct MainContentView: View {
    let selectedTab: SidebarTab

    var body: some View {
        switch selectedTab {
        case .setup:    SetupView()
        case .models:   ModelsView()
        case .settings: SettingsView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
