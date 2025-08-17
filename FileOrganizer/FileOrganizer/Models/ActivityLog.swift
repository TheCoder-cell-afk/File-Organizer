//
//  ActivityLog.swift
//  FileOrganizer
//
//  
//

import Foundation
import Combine

struct ActivityLog: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let fileName: String
    let fileType: String
    let action: Action
    let sourcePath: String
    let destinationPath: String?
    let details: String?
    
    init(timestamp: Date, fileName: String, fileType: String, action: Action, sourcePath: String, destinationPath: String?, details: String?) {
        self.id = UUID()
        self.timestamp = timestamp
        self.fileName = fileName
        self.fileType = fileType
        self.action = action
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.details = details
    }
    
    enum Action: String, Codable {
        case moved = "Moved"
        case tracked = "Tracked"
        case cleaned = "Cleaned"
        case error = "Error"
        case mounted = "Mounted"
        case launched = "Launched"
        case pending = "Pending" // New action for files that need manual organization
        case reverted = "Reverted" // New action for when files are moved back to Downloads
    }
}

// MARK: - Activity Log Manager
class ActivityLogManager: ObservableObject {
    @Published var logs: [ActivityLog] = []
    private let userDefaults = UserDefaults.standard
    private let logsKey = "FileOrganizerActivityLogs"
    private let maxLogs = 1000
    
    init() {
        loadLogs()
    }
    
    func addLog(_ log: ActivityLog) {
        logs.insert(log, at: 0)
        
        // Keep only the most recent logs
        if logs.count > maxLogs {
            logs = Array(logs.prefix(maxLogs))
        }
        
        saveLogs()
    }
    
    func clearLogs() {
        logs.removeAll()
        saveLogs()
    }
    
    func removeLog(withId id: UUID) {
        logs.removeAll { $0.id == id }
        saveLogs()
    }
    
    private func loadLogs() {
        if let data = userDefaults.data(forKey: logsKey),
           let decodedLogs = try? JSONDecoder().decode([ActivityLog].self, from: data) {
            self.logs = decodedLogs
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            userDefaults.set(encoded, forKey: logsKey)
        }
    }
}


