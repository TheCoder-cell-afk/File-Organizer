//
//  DashboardView.swift
//  FileOrganizer
//
//  
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var fileOrganizer = FileOrganizer.shared
    @StateObject private var preferences = Preferences.shared
    @StateObject private var activityLogManager = FileOrganizer.shared.getActivityLogManager()
    
    @State private var searchText = ""
    @State private var selectedLogType: ActivityLog.Action?
    
    var filteredLogs: [ActivityLog] {
        activityLogManager.logs.filter { log in
            let matchesSearch = searchText.isEmpty || log.fileName.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedLogType == nil || log.action == selectedLogType
            return matchesSearch && matchesType
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
                .tahoeGlassBackground()
            
            Divider()
            
            // Status bar
            statusBar
                .padding()
                .tahoeGlassBackground()
            
            Divider()
            
            // Activity logs
            if activityLogManager.logs.isEmpty {
                emptyStateView
            } else {
                activityLogList
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("File Organizer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Automatically organize your Downloads folder")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Organize all pending files button
                Button(action: organizeAllPending) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Organize All Pending")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!preferences.hasRequestedPermission || getPendingFilesCount() == 0)
                .fixedSize()
                
                // Revert all recent moves button
                Button(action: revertAllRecent) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Revert All Recent")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!preferences.hasRequestedPermission || getRecentMovesCount() == 0)
                .fixedSize()
                
                // Revert all moved files button
                Button(action: revertAllMoved) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                        Text("Revert All Moved")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!preferences.hasRequestedPermission || getAllMovedFilesCount() == 0)
                .fixedSize()
                
                // Manual organize button (for existing files)
                Button(action: organizeNow) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Scan Downloads")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!preferences.hasRequestedPermission)
                .fixedSize()
                
                // Refresh button for manual changes
                Button(action: refreshDownloads) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!preferences.hasRequestedPermission)
                .fixedSize()
            }
            .padding(.horizontal)
        }
    }
    
    private var statusBar: some View {
        HStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search files...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            // Filter by action type
            Picker("Filter", selection: $selectedLogType) {
                Text("All Actions").tag(ActivityLog.Action?.none)
                ForEach([ActivityLog.Action.moved, .pending, .reverted, .tracked, .cleaned, .mounted, .launched, .error], id: \.self) { action in
                    Text(action.rawValue).tag(Optional(action))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            Spacer()
            
            // Clear logs button
            Button(action: { activityLogManager.clearLogs() }) {
                Label("Clear Logs", systemImage: "trash")
            }
            .disabled(activityLogManager.logs.isEmpty)
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(fileOrganizer.isMonitoring ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(fileOrganizer.isMonitoring ? "Monitoring" : "Not Monitoring")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if getPendingFilesCount() > 0 {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(getPendingFilesCount()) pending")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: fileOrganizer.isMonitoring ? "doc.text.magnifyingglass" : "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(fileOrganizer.isMonitoring ? "No Activity Yet" : "Start Monitoring")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(fileOrganizer.isMonitoring ? "Files will appear here as they are downloaded and organized" : "Click 'Start Monitoring' to begin organizing your Downloads folder")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
    
    private var activityLogList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredLogs) { log in
                    ActivityLogRow(log: log)
                        .background(Color(NSColor.textBackgroundColor))
                }
            }
            .padding(.vertical, 1)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func toggleMonitoring() {
        if fileOrganizer.isMonitoring {
            fileOrganizer.stopMonitoring()
        } else {
            fileOrganizer.startMonitoring()
        }
    }
    
    private func organizeNow() {
        print("🎯 DashboardView: organizeNow() button pressed")
        fileOrganizer.organizeExistingFiles()
    }
    
    private func organizeAllPending() {
        print("🎯 DashboardView: organizeAllPending() button pressed")
        fileOrganizer.organizeAllPendingFiles()
    }
    
    private func revertAllRecent() {
        print("🎯 DashboardView: revertAllRecent() button pressed")
        fileOrganizer.revertAllRecentMoves()
    }
    
    private func revertAllMoved() {
        print("🎯 DashboardView: revertAllMoved() button pressed")
        fileOrganizer.revertAllMovedFiles()
    }
    
    private func refreshDownloads() {
        print("🎯 DashboardView: refreshDownloads() button pressed")
        fileOrganizer.refreshDownloadsFolder()
    }
    
    private func getPendingFilesCount() -> Int {
        return fileOrganizer.pendingFiles.count
    }
    
    private func getRecentMovesCount() -> Int {
        return fileOrganizer.recentMoves.count
    }
    
    private func getAllMovedFilesCount() -> Int {
        return fileOrganizer.allMovedFiles.count
    }
}

// MARK: - Activity Log Row
struct ActivityLogRow: View {
    let log: ActivityLog
    @StateObject private var fileOrganizer = FileOrganizer.shared
    
    private var actionColor: Color {
        switch log.action {
        case .moved: return .blue
        case .tracked: return .orange
        case .cleaned: return .green
        case .mounted: return .purple
        case .launched: return .indigo
        case .error: return .red
        case .pending: return .yellow
        case .reverted: return .mint
        }
    }
    
    private var actionIcon: String {
        switch log.action {
        case .moved: return "arrow.right.circle.fill"
        case .tracked: return "eye.circle.fill"
        case .cleaned: return "sparkles"
        case .mounted: return "externaldrive.fill"
        case .launched: return "play.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .pending: return "clock.circle.fill"
        case .reverted: return "arrow.uturn.backward.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Action icon
            Image(systemName: actionIcon)
                .font(.title2)
                .foregroundColor(actionColor)
                .frame(width: 30)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.fileName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(log.fileType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if let details = log.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let destination = log.destinationPath {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                        Text(URL(fileURLWithPath: destination).deletingLastPathComponent().lastPathComponent)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons based on log type
            if log.action == .pending {
                Button("Organize") {
                    fileOrganizer.organizeFile(log)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if log.action == .moved {
                Button("Revert") {
                    fileOrganizer.revertFile(log)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.orange)
            }
            
            Text(log.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
    }
}

#Preview {
    DashboardView()
}

