//
//  Preferences.swift
//  FileOrganizer
//
//  
//

import Foundation
import Combine

class Preferences: ObservableObject {
    static let shared = Preferences()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Published Properties
    @Published var isEnabled: Bool {
        didSet { userDefaults.set(isEnabled, forKey: "isEnabled") }
    }
    
    @Published var cleanInstallersImmediately: Bool {
        didSet { userDefaults.set(cleanInstallersImmediately, forKey: "cleanInstallersImmediately") }
    }
    
    @Published var cleanAfterFirstUse: Bool {
        didSet { userDefaults.set(cleanAfterFirstUse, forKey: "cleanAfterFirstUse") }
    }
    
    @Published var autoCleanUnusedInstallers: Bool {
        didSet { userDefaults.set(autoCleanUnusedInstallers, forKey: "autoCleanUnusedInstallers") }
    }
    
    @Published var autoCleanDays: Int {
        didSet { userDefaults.set(autoCleanDays, forKey: "autoCleanDays") }
    }
    
    @Published var hasRequestedPermission: Bool {
        didSet { userDefaults.set(hasRequestedPermission, forKey: "hasRequestedPermission") }
    }
    
    @Published var confirmBeforeMoving: Bool {
        didSet { userDefaults.set(confirmBeforeMoving, forKey: "confirmBeforeMoving") }
    }
    
    @Published var customDestinations: [String: String] {
        didSet { 
            if let encoded = try? JSONEncoder().encode(customDestinations) {
                userDefaults.set(encoded, forKey: "customDestinations")
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        self.isEnabled = userDefaults.bool(forKey: "isEnabled")
        self.cleanInstallersImmediately = userDefaults.bool(forKey: "cleanInstallersImmediately")
        self.cleanAfterFirstUse = userDefaults.object(forKey: "cleanAfterFirstUse") as? Bool ?? true
        self.autoCleanUnusedInstallers = userDefaults.object(forKey: "autoCleanUnusedInstallers") as? Bool ?? true
        self.autoCleanDays = userDefaults.object(forKey: "autoCleanDays") as? Int ?? 7
        self.hasRequestedPermission = userDefaults.bool(forKey: "hasRequestedPermission")
        self.confirmBeforeMoving = userDefaults.object(forKey: "confirmBeforeMoving") as? Bool ?? false // Changed default to false
        
        if let data = userDefaults.data(forKey: "customDestinations"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.customDestinations = decoded
        } else {
            self.customDestinations = [:]
        }
    }
    
    // MARK: - Methods
    func getDestination(for fileType: FileType) -> String {
        return customDestinations[fileType.rawValue] ?? fileType.destinationPath
    }
    
    func setCustomDestination(for fileType: FileType, path: String) {
        customDestinations[fileType.rawValue] = path
    }
    
    func resetDestination(for fileType: FileType) {
        customDestinations.removeValue(forKey: fileType.rawValue)
    }
    
    func resetAllSettings() {
        isEnabled = false
        cleanInstallersImmediately = false
        cleanAfterFirstUse = true
        autoCleanUnusedInstallers = true
        autoCleanDays = 7
        confirmBeforeMoving = false // Changed default to false
        customDestinations = [:]
    }
}

