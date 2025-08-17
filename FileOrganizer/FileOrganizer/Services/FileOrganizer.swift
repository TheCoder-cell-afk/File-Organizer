//
//  FileOrganizer.swift
//  FileOrganizer
//
//  
//

import Foundation
import AppKit
import Combine
import UserNotifications
import SwiftUI

class FileOrganizer: ObservableObject {
    static let shared = FileOrganizer()
    
    @Published var isMonitoring = false
    @Published var lastError: String?
    
    private var fileSystemSource: DispatchSourceFileSystemObject?
    private var periodicTimer: Timer?
    private var monitorQueue = DispatchQueue(label: "com.fileorganizer.monitor", attributes: .concurrent)
    private var processingQueue = DispatchQueue(label: "com.fileorganizer.processing")
    
    private let activityLogManager = ActivityLogManager()
    private let installerTracker = InstallerTracker.shared
    private let preferences = Preferences.shared
    
    private var downloadsURL: URL {
        // Prefer absolute user Downloads path if accessible; fallback to sandbox container path
        let absolutePath = "~/Downloads"
        let absoluteURL = URL(fileURLWithPath: absolutePath)
        if FileManager.default.fileExists(atPath: absoluteURL.path) {
            return absoluteURL
        }
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotifications()
        setupWorkspaceNotifications()
        startPeriodicCleanup()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        guard !isMonitoring else { 
            print("📱 FileOrganizer: Already monitoring, skipping...")
            return 
        }
        
        print("🚀 FileOrganizer: Starting monitoring of Downloads folder...")
        
        // Create all destination folders first
        createDestinationFolders()
        
        let fileDescriptor = open(downloadsURL.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("❌ FileOrganizer: Failed to open Downloads folder for monitoring")
            DispatchQueue.main.async {
                self.lastError = "Failed to open Downloads folder for monitoring"
            }
            return
        }
        
        print("✅ FileOrganizer: Successfully opened Downloads folder for monitoring")
        
        fileSystemSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .delete, .rename, .link, .funlock],
            queue: monitorQueue
        )
        
        fileSystemSource?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }
        
        fileSystemSource?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileSystemSource?.resume()
        
        print("🎯 FileOrganizer: File system monitoring started and resumed")
        
        DispatchQueue.main.async {
            self.isMonitoring = true
        }
        
        print("📂 FileOrganizer: Starting initial scan of Downloads folder...")
        // Initial scan of Downloads folder - only mark files as pending, don't organize
        scanDownloadsFolderForPendingFiles()
        
        // Start periodic backup scan every 10 seconds to catch missed files
        print("⏰ FileOrganizer: Starting periodic backup scan every 10 seconds")
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            print("🔄 FileOrganizer: Running periodic backup scan...")
            self?.scanDownloadsFolderForPendingFiles()
        }
    }
    
    func stopMonitoring() {
        print("🛑 FileOrganizer: Stopping file monitoring...")
        fileSystemSource?.cancel()
        fileSystemSource = nil
        periodicTimer?.invalidate()
        periodicTimer = nil
        DispatchQueue.main.async {
            self.isMonitoring = false
        }
    }
    
    // MARK: - File System Event Handling
    private func handleFileSystemEvent() {
        print("🔍 File system event detected in Downloads folder")
        // Smaller delay to ensure file write is complete but still responsive
        processingQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("📂 Starting scan of Downloads folder after file system event")
            // Only scan for new files, don't organize existing ones automatically
            self?.scanDownloadsFolderForNewFiles()
        }
    }
    
    // MARK: - Folder Creation
    private func createDestinationFolders() {
        let fileManager = FileManager.default
        
        for fileType in FileType.allCases {
            let destinationPath = preferences.getDestination(for: fileType)
            let expandedPath = NSString(string: destinationPath).expandingTildeInPath
            let destinationURL = URL(fileURLWithPath: expandedPath)
            
            // Check if we have a security-scoped bookmark for this location
            if let bookmarkedURL = BookmarkManager.shared.resolveURL(for: fileType) {
                let _ = bookmarkedURL.startAccessingSecurityScopedResource()
                defer { bookmarkedURL.stopAccessingSecurityScopedResource() }
                
                do {
                    try fileManager.createDirectory(at: bookmarkedURL, withIntermediateDirectories: true, attributes: nil)
                    print("✅ Created destination folder (bookmarked): \(bookmarkedURL.path)")
                } catch {
                    print("❌ Failed to create bookmarked folder \(bookmarkedURL.path): \(error)")
                }
            } else {
                // Try to create with default path (may fail due to sandboxing for system directories)
                do {
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                    print("✅ Created destination folder: \(destinationURL.path)")
                } catch {
                    print("⚠️ Could not create folder \(destinationURL.path): \(error)")
                    
                    // For system directories like Documents, Pictures, etc., we need user permission
                    if destinationPath.contains("~/Documents") || destinationPath.contains("~/Pictures") || 
                       destinationPath.contains("~/Movies") || destinationPath.contains("~/Music") {
                        print("💡 Folder \(destinationURL.path) requires user permission - use Settings to select a custom location")
                        
                        // Log this as a helpful message for the user
                        DispatchQueue.main.async {
                            let log = ActivityLog(
                                timestamp: Date(),
                                fileName: "System Folder Access",
                                fileType: fileType.rawValue,
                                action: .error,
                                sourcePath: destinationURL.path,
                                destinationPath: nil,
                                details: "Cannot access system folder. Use Settings to choose custom location."
                            )
                            self.activityLogManager.addLog(log)
                        }
                    }
                }
            }
        }
    }
    
    private func scanDownloadsFolder() {
        print("🚀 STARTING scanDownloadsFolder() - Path: \(downloadsURL.path)")
        
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: downloadsURL,
                includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            print("📂 Found \(contents.count) items in Downloads folder")
            
            // Print all files found for debugging
            for (index, fileURL) in contents.enumerated() {
                print("  [\(index + 1)] \(fileURL.lastPathComponent)")
            }
            
            // Sort by modification date to process newest files first
            let sortedContents = contents.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return date1 > date2
            }
            
            print("🔄 Processing \(sortedContents.count) files in order...")
            
            for (index, fileURL) in sortedContents.enumerated() {
                print("⚡ Processing file \(index + 1)/\(sortedContents.count): \(fileURL.lastPathComponent)")
                processFile(at: fileURL)
            }
            
            print("✅ Finished scanning Downloads folder")
        } catch {
            print("❌ Error scanning Downloads folder: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.lastError = "Error scanning Downloads folder: \(error.localizedDescription)"
            }
        }
    }
    
    private func processFile(at fileURL: URL) {
        let fileManager = FileManager.default
        
        // Skip if file doesn't exist (might have been moved already)
        guard fileManager.fileExists(atPath: fileURL.path) else { 
            print("⚠️ File doesn't exist: \(fileURL.path)")
            return 
        }
        
        // Skip directories
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)
        if isDirectory.boolValue { 
            print("📁 Skipping directory: \(fileURL.path)")
            return 
        }
        
        // Skip system files and temp files
        let fileName = fileURL.lastPathComponent
        if fileName.hasPrefix(".") || fileName.hasSuffix(".tmp") || fileName.hasSuffix(".download") || 
           fileName.hasSuffix(".crdownload") || fileName.hasSuffix(".part") || fileName.contains(".part.") {
            print("🚫 Skipping system/temp file: \(fileName)")
            return
        }
        
        let fileExtension = fileURL.pathExtension.lowercased()
        let fileType = FileType.from(fileExtension: fileExtension)
        
        print("✅ Processing file: \(fileName) (extension: \(fileExtension), type: \(fileType.rawValue))")
        
        // Special handling for installers
        if fileType == .installer {
            print("📦 Handling installer: \(fileName)")
            handleInstaller(at: fileURL, fileName: fileName, fileExtension: fileExtension)
        } else {
            // Move other files immediately
            print("📤 Moving file: \(fileName) to \(fileType.rawValue)")
            moveFile(from: fileURL, fileType: fileType)
        }
    }
    
    private func handleInstaller(at fileURL: URL, fileName: String, fileExtension: String) {
        // Track the installer
        installerTracker.trackInstaller(at: fileURL.path, fileName: fileName, fileType: fileExtension)
        
        // Log tracking
        let log = ActivityLog(
            timestamp: Date(),
            fileName: fileName,
            fileType: FileType.installer.rawValue,
            action: .tracked,
            sourcePath: fileURL.path,
            destinationPath: nil,
            details: "Installer tracked for monitoring"
        )
        DispatchQueue.main.async {
            self.activityLogManager.addLog(log)
        }
        
        // If set to clean immediately, move it now
        if preferences.cleanInstallersImmediately {
            moveFile(from: fileURL, fileType: .installer)
        }
    }
    
    private func moveFile(from sourceURL: URL, fileType: FileType) {
        // Check if confirmation is required
        if preferences.confirmBeforeMoving {
            print("❓ Asking user for confirmation before moving: \(sourceURL.lastPathComponent)")
            DispatchQueue.main.async {
                self.showConfirmationDialog(for: sourceURL, fileType: fileType)
            }
            return
        }
        
        // Proceed with automatic move
        print("🚀 Automatically organizing: \(sourceURL.lastPathComponent) → \(fileType.rawValue)")
        performFileMove(from: sourceURL, fileType: fileType)
    }
    
    private func performFileMove(from sourceURL: URL, fileType: FileType) {
        let fileManager = FileManager.default
        let destinationPath = preferences.getDestination(for: fileType)
        let expandedPath = NSString(string: destinationPath).expandingTildeInPath

        // Prefer bookmarked URL if available
        let bookmarkedURL = BookmarkManager.shared.resolveURL(for: fileType)
        let destinationDir = bookmarkedURL ?? URL(fileURLWithPath: expandedPath)

        // Start security scope if using bookmark
        let _ = destinationDir.startAccessingSecurityScopedResource()
        defer { destinationDir.stopAccessingSecurityScopedResource() }

        do {
            // Create destination directory if it doesn't exist
            try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)

            // Generate unique filename if needed
            let destinationURL = destinationDir.appendingPathComponent(sourceURL.lastPathComponent)
            let finalURL = generateUniqueFileName(for: destinationURL)

            // Move the file
            try fileManager.moveItem(at: sourceURL, to: finalURL)

            // Log the move
            let log = ActivityLog(
                timestamp: Date(),
                fileName: sourceURL.lastPathComponent,
                fileType: fileType.rawValue,
                action: .moved,
                sourcePath: sourceURL.path,
                destinationPath: finalURL.path,
                details: nil
            )
            DispatchQueue.main.async {
                self.activityLogManager.addLog(log)
            }

            // Remove tracking if it was an installer
            if fileType == .installer {
                installerTracker.removeTracking(for: sourceURL.path)
            }

            // Send notification
            if fileType == .installer {
                sendNotification(
                    title: "Installer Cleaned",
                    body: "\(sourceURL.lastPathComponent) has been moved to Junk Installers"
                )
            }

        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to move file: \(error.localizedDescription)"
            }

            // Provide helpful error message for system folder access issues
            var errorDetails = error.localizedDescription
            if destinationPath.contains("~/Documents") || destinationPath.contains("~/Pictures") || 
               destinationPath.contains("~/Movies") || destinationPath.contains("~/Music") {
                errorDetails = "Cannot access system folder. Go to Settings → Destination Folders and choose a custom location."
            }

            // Log error
            let log = ActivityLog(
                timestamp: Date(),
                fileName: sourceURL.lastPathComponent,
                fileType: fileType.rawValue,
                action: .error,
                sourcePath: sourceURL.path,
                destinationPath: nil,
                details: errorDetails
            )
            DispatchQueue.main.async {
                self.activityLogManager.addLog(log)
            }
        }
    }
    
    private func generateUniqueFileName(for url: URL) -> URL {
        let fileManager = FileManager.default
        var finalURL = url
        var counter = 1
        
        while fileManager.fileExists(atPath: finalURL.path) {
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newName = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
            finalURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }
        
        return finalURL
    }
    
    // MARK: - Workspace Notifications
    private func setupWorkspaceNotifications() {
        // Monitor for DMG mounts
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(volumeMounted(_:)),
            name: NSWorkspace.didMountNotification,
            object: nil
        )
        
        // Monitor for app launches
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }
    
    @objc private func volumeMounted(_ notification: Notification) {
        guard let volume = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        
        // Check if this is a DMG mount
        processingQueue.async { [weak self] in
            self?.checkForMountedDMG(volumeURL: volume)
        }
    }
    
    @objc private func appLaunched(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleURL = app.bundleURL else { return }
        
        processingQueue.async { [weak self] in
            self?.checkForLaunchedApp(bundleURL: bundleURL)
        }
    }
    
    private func checkForMountedDMG(volumeURL: URL) {
        // Find tracked DMGs and check if they've been mounted
        for (path, installer) in installerTracker.trackedInstallers where installer.fileType == "dmg" && !installer.hasBeenUsed {
            installerTracker.markAsUsed(path: path)
            
            // Log the mount
            let log = ActivityLog(
                timestamp: Date(),
                fileName: installer.fileName,
                fileType: FileType.installer.rawValue,
                action: .mounted,
                sourcePath: path,
                destinationPath: nil,
                details: "DMG mounted"
            )
            DispatchQueue.main.async {
                self.activityLogManager.addLog(log)
            }
            
            // Move if configured to clean after first use
            if preferences.cleanAfterFirstUse {
                if FileManager.default.fileExists(atPath: path) {
                    let fileURL = URL(fileURLWithPath: path)
                    moveFile(from: fileURL, fileType: .installer)
                }
            }
        }
    }
    
    private func checkForLaunchedApp(bundleURL: URL) {
        let bundleName = bundleURL.lastPathComponent
        
        // Find tracked apps
        for (path, installer) in installerTracker.trackedInstallers where installer.fileType == "app" && !installer.hasBeenUsed {
            if installer.fileName == bundleName {
                installerTracker.markAsUsed(path: path)
                
                // Log the launch
                let log = ActivityLog(
                    timestamp: Date(),
                    fileName: installer.fileName,
                    fileType: FileType.installer.rawValue,
                    action: .launched,
                    sourcePath: path,
                    destinationPath: nil,
                    details: "App launched"
                )
                DispatchQueue.main.async {
                    self.activityLogManager.addLog(log)
                }
                
                // Move if configured to clean after first use
                if preferences.cleanAfterFirstUse {
                    if FileManager.default.fileExists(atPath: path) {
                        let fileURL = URL(fileURLWithPath: path)
                        moveFile(from: fileURL, fileType: .installer)
                    }
                }
            }
        }
    }
    
    // MARK: - Periodic Cleanup
    private func startPeriodicCleanup() {
        // Run cleanup check every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performPeriodicCleanup()
            }
            .store(in: &cancellables)
    }
    
    private func performPeriodicCleanup() {
        guard preferences.autoCleanUnusedInstallers else { return }
        
        let unusedInstallers = installerTracker.getUnusedInstallersOlderThan(days: preferences.autoCleanDays)
        
        for installer in unusedInstallers {
            if FileManager.default.fileExists(atPath: installer.filePath) {
                let fileURL = URL(fileURLWithPath: installer.filePath)
                moveFile(from: fileURL, fileType: .installer)
                
                // Log auto-cleanup
                let log = ActivityLog(
                    timestamp: Date(),
                    fileName: installer.fileName,
                    fileType: FileType.installer.rawValue,
                    action: .cleaned,
                    sourcePath: installer.filePath,
                    destinationPath: nil,
                    details: "Auto-cleaned after \(preferences.autoCleanDays) days"
                )
                DispatchQueue.main.async {
                    self.activityLogManager.addLog(log)
                }
            }
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Public Getters
    func getActivityLogManager() -> ActivityLogManager {
        return activityLogManager
    }
    
    var pendingFiles: [ActivityLog] {
        return activityLogManager.logs.filter { $0.action == .pending }
    }
    
    var recentMoves: [ActivityLog] {
        let cutoffTime = Date().addingTimeInterval(-TimeInterval(30 * 60)) // Last 30 minutes
        return activityLogManager.logs.filter { log in
            log.action == .moved && log.timestamp > cutoffTime
        }
    }
    
    var allMovedFiles: [ActivityLog] {
        return activityLogManager.logs.filter { log in
            log.action == .moved
        }
    }
    
    func organizeExistingFiles() {
        print("🎯 organizeExistingFiles() called - triggering manual scan")
        processingQueue.async { [weak self] in
            print("🔄 Executing scanDownloadsFolder on processing queue")
            self?.scanDownloadsFolder()
        }
    }
    
    // MARK: - Pending Files Management
    func scanDownloadsFolderForPendingFiles() {
        print("🔍 Scanning Downloads folder for pending files...")
        processingQueue.async { [weak self] in
            self?.processPendingFiles()
        }
    }
    
    // MARK: - New Files Detection (Auto-organization)
    func scanDownloadsFolderForNewFiles() {
        print("🆕 Scanning Downloads folder for NEW files to auto-organize...")
        processingQueue.async { [weak self] in
            self?.processNewFiles()
        }
    }
    
    private func processNewFiles() {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
            
            // Filter out directories and system files
            let files = contents.filter { fileURL in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)
                
                let fileName = fileURL.lastPathComponent
                let isSystemFile = fileName.hasPrefix(".") || fileName.hasSuffix(".tmp") || fileName.hasSuffix(".download") || 
                                   fileName.hasSuffix(".crdownload") || fileName.hasSuffix(".part") || fileName.contains(".part.")
                
                return !isDirectory.boolValue && !isSystemFile
            }
            
            print("📁 Found \(files.count) files to check for new status")
            
            for fileURL in files {
                let fileName = fileURL.lastPathComponent
                let fileExtension = fileURL.pathExtension.lowercased()
                
                // Skip files with no extension
                guard !fileExtension.isEmpty else {
                    print("⚠️ Skipping file with no extension: \(fileName)")
                    continue
                }
                
                let fileType = FileType.from(fileExtension: fileExtension)
                
                // Check if this file is already logged (means it's not new)
                let existingLog = activityLogManager.logs.first { log in
                    log.sourcePath == fileURL.path
                }
                
                if existingLog == nil {
                    // This is a NEW file - organize it automatically
                    print("🆕 Auto-organizing new file: \(fileName)")
                    
                    // Special handling for installers
                    if fileType == .installer {
                        handleInstaller(at: fileURL, fileName: fileName, fileExtension: fileExtension)
                    } else {
                        // Move other files immediately (with confirmation if enabled)
                        moveFile(from: fileURL, fileType: fileType)
                    }
                }
            }
            
        } catch {
            print("❌ Error scanning Downloads folder for new files: \(error.localizedDescription)")
        }
    }
    
    private func processPendingFiles() {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            // Filter out directories and system files
            let files = contents.filter { fileURL in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)
                
                let fileName = fileURL.lastPathComponent
                let isSystemFile = fileName.hasPrefix(".") || fileName.hasSuffix(".tmp") || fileName.hasSuffix(".download") || 
                                   fileName.hasSuffix(".crdownload") || fileName.hasSuffix(".part") || fileName.contains(".part.")
                
                return !isDirectory.boolValue && !isSystemFile
            }
            
            print("📁 Found \(files.count) files to check for pending status")
            
            for fileURL in files {
                let fileName = fileURL.lastPathComponent
                let fileExtension = fileURL.pathExtension.lowercased()
                
                // Skip files with no extension
                guard !fileExtension.isEmpty else {
                    print("⚠️ Skipping file with no extension: \(fileName)")
                    continue
                }
                
                let fileType = FileType.from(fileExtension: fileExtension)
                
                // Check if this file is already logged
                let existingLog = activityLogManager.logs.first { log in
                    log.sourcePath == fileURL.path && (log.action == .moved || log.action == .pending)
                }
                
                if existingLog == nil {
                    // Mark as pending for manual organization
                    let log = ActivityLog(
                        timestamp: Date(),
                        fileName: fileName,
                        fileType: fileType.rawValue,
                        action: .pending,
                        sourcePath: fileURL.path,
                        destinationPath: nil,
                        details: "File pending organization"
                    )
                    DispatchQueue.main.async {
                        self.activityLogManager.addLog(log)
                    }
                    print("📋 Marked as pending: \(fileName)")
                }
            }
            
        } catch {
            print("❌ Error scanning Downloads folder for pending files: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Manual Organization
    func organizeFile(_ log: ActivityLog) {
        guard log.action == .pending else { return }
        
        let fileURL = URL(fileURLWithPath: log.sourcePath)
        let fileExtension = fileURL.pathExtension.lowercased()
        
        // Skip files with no extension
        guard !fileExtension.isEmpty else {
            print("⚠️ Cannot organize file with no extension: \(log.fileName)")
            return
        }
        
        let fileType = FileType.from(fileExtension: fileExtension)
        
        // Move file without confirmation (manual organization)
        performFileMove(from: fileURL, fileType: fileType)
        
        // Update log to show it was moved
        let updatedLog = ActivityLog(
            timestamp: Date(),
            fileName: log.fileName,
            fileType: log.fileType,
            action: .moved,
            sourcePath: log.sourcePath,
            destinationPath: preferences.getDestination(for: fileType),
            details: "Manually organized"
        )
        
        // Remove the pending log and add the moved log
        DispatchQueue.main.async {
            self.activityLogManager.removeLog(withId: log.id)
            self.activityLogManager.addLog(updatedLog)
        }
    }
    
    func revertFile(_ log: ActivityLog) {
        guard log.action == .moved else { return }
        
        let fileManager = FileManager.default
        let downloadsURL = self.downloadsURL
        
        // Get the current file location from the destination path
        guard let destinationPath = log.destinationPath else { return }
        let currentFileURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(log.fileName)
        
        // Check if file still exists at destination
        guard fileManager.fileExists(atPath: currentFileURL.path) else {
            print("⚠️ File no longer exists at destination: \(currentFileURL.path)")
            return
        }
        
        // Move file back to Downloads
        let targetURL = downloadsURL.appendingPathComponent(log.fileName)
        
        do {
            // If a file with the same name already exists in Downloads, add a number suffix
            var finalTargetURL = targetURL
            var counter = 1
            while fileManager.fileExists(atPath: finalTargetURL.path) {
                let fileNameWithoutExt = targetURL.deletingPathExtension().lastPathComponent
                let fileExt = targetURL.pathExtension
                finalTargetURL = downloadsURL.appendingPathComponent("\(fileNameWithoutExt)_\(counter).\(fileExt)")
                counter += 1
            }
            
            try fileManager.moveItem(at: currentFileURL, to: finalTargetURL)
            
            // Add reverted log
            let revertedLog = ActivityLog(
                timestamp: Date(),
                fileName: log.fileName,
                fileType: log.fileType,
                action: .reverted,
                sourcePath: currentFileURL.path,
                destinationPath: finalTargetURL.path,
                details: "Moved back to Downloads"
            )
            
            // Remove the moved log and add the reverted log
            DispatchQueue.main.async {
                self.activityLogManager.removeLog(withId: log.id)
                self.activityLogManager.addLog(revertedLog)
            }
            
            print("✅ Successfully reverted \(log.fileName) back to Downloads")
            
        } catch {
            print("❌ Error reverting file: \(error)")
            
            // Add error log
            let errorLog = ActivityLog(
                timestamp: Date(),
                fileName: log.fileName,
                fileType: log.fileType,
                action: .error,
                sourcePath: currentFileURL.path,
                destinationPath: nil,
                details: "Failed to revert: \(error.localizedDescription)"
            )
            
            DispatchQueue.main.async {
                self.activityLogManager.addLog(errorLog)
            }
        }
    }
    
    func organizeAllPendingFiles() {
        let pendingLogs = activityLogManager.logs.filter { $0.action == .pending }
        print("🚀 Organizing \(pendingLogs.count) pending files...")
        
        for log in pendingLogs {
            organizeFile(log)
        }
    }
    
    func revertAllRecentMoves(withinMinutes minutes: Int = 30) {
        let cutoffTime = Date().addingTimeInterval(-TimeInterval(minutes * 60))
        let recentMoves = activityLogManager.logs.filter { log in
            log.action == .moved && log.timestamp > cutoffTime
        }
        
        print("🔄 Reverting \(recentMoves.count) files moved in the last \(minutes) minutes")
        
        for log in recentMoves {
            revertFile(log)
        }
    }
    
    func revertAllMovedFiles() {
        let allMoves = activityLogManager.logs.filter { log in
            log.action == .moved
        }
        
        print("🔄 Reverting ALL \(allMoves.count) files that have ever been moved")
        
        for log in allMoves {
            revertFile(log)
        }
    }
    
    func refreshDownloadsFolder() {
        print("🔄 Refreshing Downloads folder - rescanning for manual changes")
        
        // Clear any pending logs since they might be outdated
        let pendingLogs = activityLogManager.logs.filter { $0.action == .pending }
        for log in pendingLogs {
            DispatchQueue.main.async {
                self.activityLogManager.removeLog(withId: log.id)
            }
        }
        
        // Rescan the Downloads folder to find current files
        scanDownloadsFolderForPendingFiles()
        
        // Update moved logs to check if files still exist at their destinations
        let movedLogs = activityLogManager.logs.filter { $0.action == .moved }
        for log in movedLogs {
            if let destinationPath = log.destinationPath {
                let fileManager = FileManager.default
                let destinationURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(log.fileName)
                
                // If the file no longer exists at destination, mark it as missing
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    print("⚠️ File no longer exists at destination: \(log.fileName)")
                    
                    // Update the log to show it's missing
                    let updatedLog = ActivityLog(
                        timestamp: log.timestamp,
                        fileName: log.fileName,
                        fileType: log.fileType,
                        action: .error,
                        sourcePath: log.sourcePath,
                        destinationPath: log.destinationPath,
                        details: "File no longer exists at destination (possibly moved manually)"
                    )
                    
                    // Replace the old log
                    DispatchQueue.main.async {
                        self.activityLogManager.removeLog(withId: log.id)
                        self.activityLogManager.addLog(updatedLog)
                    }
                }
            }
        }
        
        print("✅ Refresh complete - Downloads folder rescanned and logs updated")
    }
    
    // MARK: - Confirmation Dialog
    private func showConfirmationDialog(for sourceURL: URL, fileType: FileType) {
        let fileName = sourceURL.lastPathComponent
        let destination = preferences.getDestination(for: fileType)
        
        let alert = NSAlert()
        alert.messageText = "Move File?"
        alert.informativeText = "Move '\(fileName)' to \(destination)?"
        alert.addButton(withTitle: "Move")
        alert.addButton(withTitle: "Skip")
        alert.addButton(withTitle: "Don't Ask Again")
        alert.alertStyle = .informational
        
        // Use the main window as parent if available
        let window = NSApplication.shared.windows.first { $0.isVisible }
        
        if let window = window {
            alert.beginSheetModal(for: window) { response in
                DispatchQueue.main.async {
                    self.handleConfirmationResponse(response, sourceURL: sourceURL, fileType: fileType)
                }
            }
        } else {
            let response = alert.runModal()
            handleConfirmationResponse(response, sourceURL: sourceURL, fileType: fileType)
        }
    }
    
    private func handleConfirmationResponse(_ response: NSApplication.ModalResponse, sourceURL: URL, fileType: FileType) {
        switch response {
        case .alertFirstButtonReturn: // Move
            performFileMove(from: sourceURL, fileType: fileType)
        case .alertSecondButtonReturn: // Skip
            print("User skipped moving file: \(sourceURL.lastPathComponent)")
        case .alertThirdButtonReturn: // Don't Ask Again
            preferences.confirmBeforeMoving = false
            performFileMove(from: sourceURL, fileType: fileType)
        default:
            break
        }
    }
}

