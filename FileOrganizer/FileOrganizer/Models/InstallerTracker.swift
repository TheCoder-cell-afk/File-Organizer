//
//  InstallerTracker.swift
//  FileOrganizer
//
//  
//

import Foundation
import Combine

struct TrackedInstaller: Codable {
    let filePath: String
    let fileName: String
    let downloadDate: Date
    var hasBeenUsed: Bool
    var usedDate: Date?
    let fileType: String // dmg, pkg, or app
}

class InstallerTracker: ObservableObject {
    static let shared = InstallerTracker()
    
    @Published var trackedInstallers: [String: TrackedInstaller] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let trackingKey = "TrackedInstallers"
    
    private init() {
        loadTrackedInstallers()
    }
    
    func trackInstaller(at path: String, fileName: String, fileType: String) {
        let installer = TrackedInstaller(
            filePath: path,
            fileName: fileName,
            downloadDate: Date(),
            hasBeenUsed: false,
            fileType: fileType
        )
        
        trackedInstallers[path] = installer
        saveTrackedInstallers()
    }
    
    func markAsUsed(path: String) {
        if var installer = trackedInstallers[path] {
            installer.hasBeenUsed = true
            installer.usedDate = Date()
            trackedInstallers[path] = installer
            saveTrackedInstallers()
        }
    }
    
    func removeTracking(for path: String) {
        trackedInstallers.removeValue(forKey: path)
        saveTrackedInstallers()
    }
    
    func getUnusedInstallersOlderThan(days: Int) -> [TrackedInstaller] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return trackedInstallers.values.filter { installer in
            !installer.hasBeenUsed && installer.downloadDate < cutoffDate
        }
    }
    
    private func loadTrackedInstallers() {
        if let data = userDefaults.data(forKey: trackingKey),
           let decoded = try? JSONDecoder().decode([String: TrackedInstaller].self, from: data) {
            self.trackedInstallers = decoded
        }
    }
    
    private func saveTrackedInstallers() {
        if let encoded = try? JSONEncoder().encode(trackedInstallers) {
            userDefaults.set(encoded, forKey: trackingKey)
        }
    }
}


