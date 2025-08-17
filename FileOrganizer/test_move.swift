#!/usr/bin/env swift

import Foundation

print("🧪 Testing basic file move functionality...")

let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
let testFileName = "swift-test-move.txt"
let testFileURL = downloadsURL.appendingPathComponent(testFileName)
let destinationDir = downloadsURL.appendingPathComponent("TestFolder")
let destinationURL = destinationDir.appendingPathComponent(testFileName)

do {
    // Create test file
    try "Test content".write(to: testFileURL, atomically: true, encoding: .utf8)
    print("✅ Created test file: \(testFileName)")
    
    // Create destination directory
    try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
    print("✅ Created destination directory: TestFolder")
    
    // Move the file
    try FileManager.default.moveItem(at: testFileURL, to: destinationURL)
    print("✅ Successfully moved file to: \(destinationURL.path)")
    
    // Verify it exists
    if FileManager.default.fileExists(atPath: destinationURL.path) {
        print("✅ File confirmed at destination")
    } else {
        print("❌ File not found at destination")
    }
    
    // Cleanup
    try FileManager.default.removeItem(at: destinationDir)
    print("✅ Cleaned up test files")
    
} catch {
    print("❌ Error: \(error)")
}

print("🏁 Test completed")
