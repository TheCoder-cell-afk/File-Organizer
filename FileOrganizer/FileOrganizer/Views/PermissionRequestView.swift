//
//  PermissionRequestView.swift
//  FileOrganizer
//
//  
//

import SwiftUI

struct PermissionRequestView: View {
    @StateObject private var preferences = Preferences.shared
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
            
            // Title and description
            VStack(spacing: 16) {
                Text("Welcome to File Organizer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("File Organizer helps you keep your Downloads folder tidy by automatically organizing files into appropriate folders.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 400)
            }
            
            // Where files will be moved
            VStack(alignment: .leading, spacing: 16) {
                Text("Files will be organized as follows:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    destinationInfo(icon: "doc.fill", type: "Documents", destination: "~/Downloads/Documents")
                    destinationInfo(icon: "photo.fill", type: "Images", destination: "~/Downloads/Images")
                    destinationInfo(icon: "video.fill", type: "Videos", destination: "~/Downloads/Videos")
                    destinationInfo(icon: "music.note", type: "Music", destination: "~/Downloads/Music")
                    destinationInfo(icon: "archivebox.fill", type: "Archives", destination: "~/Downloads/Archives")
                    destinationInfo(icon: "app.badge", type: "Installers", destination: "~/Downloads/Junk Installers")
                }
                .padding()
                .tahoeGlassBackground()
            }
            
            // Privacy note
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("File Organizer only accesses your Downloads folder and the destination folders you specify.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: 450)
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Not Now") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Enable File Organizer") {
                    preferences.hasRequestedPermission = true
                    preferences.isEnabled = true
                    
                    // Start monitoring immediately
                    FileOrganizer.shared.startMonitoring()
                    
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(width: 600)
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )

    }
    
    private func destinationInfo(icon: String, type: String, destination: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(type)
                .font(.body)
                .frame(width: 80, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(destination)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PermissionRequestView()
}

