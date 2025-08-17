#!/usr/bin/env swift

import Foundation

// Simple test to check Downloads folder content
let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

print("🚀 Testing Downloads folder scanning...")
print("📁 Downloads path: \(downloadsURL.path)")

do {
    let contents = try FileManager.default.contentsOfDirectory(
        at: downloadsURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    )
    
    print("📂 Found \(contents.count) items:")
    
    for (index, fileURL) in contents.enumerated() {
        let fileName = fileURL.lastPathComponent
        let fileExtension = fileURL.pathExtension.lowercased()
        print("  [\(index + 1)] \(fileName) (.\(fileExtension))")
        
        // Test file type detection
        if ["pdf", "docx", "txt", "rtf", "md"].contains(fileExtension) {
            print("      → Should move to: ~/Downloads/Documents")
        } else if ["jpg", "jpeg", "png", "gif", "heic", "svg"].contains(fileExtension) {
            print("      → Should move to: ~/Downloads/Images")
        } else if ["mp4", "mov", "avi", "mkv"].contains(fileExtension) {
            print("      → Should move to: ~/Downloads/Videos")
        } else if ["mp3", "wav", "flac", "m4a"].contains(fileExtension) {
            print("      → Should move to: ~/Downloads/Music")
        } else if ["zip", "rar", "7z", "tar", "gz"].contains(fileExtension) {
            print("      → Should move to: ~/Downloads/Archives")
        } else if ["dmg", "pkg", "app"].contains(fileExtension) {
            print("      → Should move to: ~/Downloads/Junk Installers")
        } else {
            print("      → Should move to: ~/Downloads/Misc")
        }
    }
} catch {
    print("❌ Error: \(error)")
}

print("✅ Test completed")
