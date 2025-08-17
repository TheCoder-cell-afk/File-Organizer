//
//  ContentView.swift
//  FileOrganizer
//
//  
//

import SwiftUI

struct ContentView: View {
    @StateObject private var preferences = Preferences.shared
    @State private var showingPermissionRequest = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(1)
        }
        .background(
            LinearGradient(colors: [Color.cyan.opacity(0.12), Color.indigo.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .onAppear {
            checkPermissions()
        }
        .sheet(isPresented: $showingPermissionRequest) {
            PermissionRequestView()
        }
    }
    
    private func checkPermissions() {
        if !preferences.hasRequestedPermission {
            showingPermissionRequest = true
        } else if preferences.isEnabled {
            // Start monitoring if enabled
            FileOrganizer.shared.startMonitoring()
        }
    }
}

#Preview {
    ContentView()
}
