//
//  SettingsView.swift
//  FileOrganizer
//
//  
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var preferences = Preferences.shared
    @State private var showingFolderPicker = false
    @State private var selectedFileType: FileType?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
                .tahoeGlassBackground()
            
            Divider()
            
            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    fileHandlingSection
                    installerSettingsSection
                    destinationFoldersSection
                    generalSettingsSection
                }
                .padding()
            }
            .background(Color.clear)
        }
        .frame(minWidth: 600, minHeight: 500)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFolderSelection(result: result)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Customize how File Organizer works")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var fileHandlingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File Handling")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $preferences.confirmBeforeMoving) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ask before organizing NEW downloads")
                        Text("Show a confirmation dialog before moving newly downloaded files (default: OFF)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .tahoeGlassBackground()
        }
    }
    
    private var installerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installer Handling")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $preferences.cleanInstallersImmediately) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clean installers immediately")
                        Text("Move DMG, PKG, and APP files to Junk Installers folder right away")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $preferences.cleanAfterFirstUse) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clean after first use")
                        Text("Move installers after they've been mounted or launched")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(preferences.cleanInstallersImmediately)
                
                Toggle(isOn: $preferences.autoCleanUnusedInstallers) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-clean unused installers")
                        Text("Automatically move installers that haven't been used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(preferences.cleanInstallersImmediately)
                
                HStack {
                    Text("Clean unused installers after")
                    
                    Picker("", selection: $preferences.autoCleanDays) {
                        ForEach([1, 3, 7, 14, 30], id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    .disabled(!preferences.autoCleanUnusedInstallers || preferences.cleanInstallersImmediately)
                }
            }
            .padding()
            .tahoeGlassBackground()
        }
    }
    
    private var destinationFoldersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Destination Folders")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(FileType.allCases, id: \.self) { fileType in
                    destinationRow(for: fileType)
                }
            }
            .padding()
            .tahoeGlassBackground()
        }
    }
    
    private func destinationRow(for fileType: FileType) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fileType.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(fileType.extensions.prefix(5).joined(separator: ", ") + (fileType.extensions.count > 5 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(currentDestinationPath(for: fileType))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 200, alignment: .trailing)
            
            Button("Change") {
                selectedFileType = fileType
                showingFolderPicker = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            if preferences.customDestinations[fileType.rawValue] != nil {
                Button(action: { preferences.resetDestination(for: fileType) }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Reset to default")
            }
        }
        .padding(.vertical, 4)
    }
    
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $preferences.isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable File Organizer")
                        Text("Turn on automatic file organization")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                Button(role: .destructive, action: resetAllSettings) {
                    Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                }
            }
            .padding()
            .tahoeGlassBackground()
        }
    }
    
    private func handleFolderSelection(result: Result<[URL], Error>) {
        if case .success(let urls) = result,
           let url = urls.first,
           let fileType = selectedFileType {
            // Persist both a readable path for UI and a security-scoped bookmark for sandbox access
            preferences.setCustomDestination(for: fileType, path: url.path)
            BookmarkManager.shared.saveBookmark(for: fileType, url: url)
        }
        selectedFileType = nil
    }

    private func currentDestinationPath(for fileType: FileType) -> String {
        if let bookmarked = BookmarkManager.shared.resolveURL(for: fileType) {
            return bookmarked.path
        }
        return preferences.getDestination(for: fileType)
    }
    
    private func resetAllSettings() {
        preferences.resetAllSettings()
    }
}

#Preview {
    SettingsView()
}

