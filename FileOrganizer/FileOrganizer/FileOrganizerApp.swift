//
//  FileOrganizerApp.swift
//  FileOrganizer
//
//  
//

import SwiftUI
import AppKit

@main
struct FileOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        // Add menu bar status
        MenuBarExtra("File Organizer", systemImage: "folder") {
            MenuBarStatusView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if FileOrganizer.shared.isMonitoring {
            let alert = NSAlert()
            alert.messageText = "File Organizer is Running"
            alert.informativeText = "The app is currently monitoring your Downloads folder. If you quit, file organization will stop. Are you sure you want to quit?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit Anyway")
            alert.addButton(withTitle: "Keep Running")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                return .terminateNow
            } else {
                return .terminateCancel
            }
        }
        return .terminateNow
    }
}

struct MenuBarStatusView: View {
    @StateObject private var fileOrganizer = FileOrganizer.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: fileOrganizer.isMonitoring ? "circle.fill" : "circle")
                    .foregroundColor(fileOrganizer.isMonitoring ? .green : .red)
                Text(fileOrganizer.isMonitoring ? "Monitoring Active" : "Monitoring Stopped")
                    .font(.headline)
            }
            
            if fileOrganizer.isMonitoring {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status: Active")
                        .foregroundColor(.green)
                    
                    let pendingCount = fileOrganizer.pendingFiles.count
                    Text("Pending: \(pendingCount)")
                        .foregroundColor(.orange)
                    
                    let movedCount = fileOrganizer.allMovedFiles.count
                    Text("Organized: \(movedCount)")
                        .foregroundColor(.blue)
                }
                .font(.caption)
            }
            
            Divider()
            
            Button("Open File Organizer") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            
            Button("Toggle Monitoring") {
                if fileOrganizer.isMonitoring {
                    fileOrganizer.stopMonitoring()
                } else {
                    fileOrganizer.startMonitoring()
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 200)
    }
}
