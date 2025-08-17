# File Organizer - Setup Guide

This guide will walk you through setting up File Organizer for development, building, and distribution.

## Prerequisites

### System Requirements
- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Git**: For version control

### Development Tools
- **Xcode**: Download from the Mac App Store or [Apple Developer](https://developer.apple.com/xcode/)
- **Command Line Tools**: Install via `xcode-select --install`

## Development Setup

### 1. Clone the Repository
```bash
git clone https://github.com/username/FileOrganizer.git
cd FileOrganizer
```

### 2. Open in Xcode
```bash
open FileOrganizer.xcodeproj
```

### 3. Configure Project Settings
1. **Select Target**: Choose "FileOrganizer" target
2. **Set Team**: Select your development team in Signing & Capabilities
3. **Bundle Identifier**: Update if needed (default: `com.example.FileOrganizer`)
4. **Deployment Target**: Set to macOS 13.0 or later

### 4. Build Configuration
- **Debug**: For development and testing
- **Release**: For production builds
- **Archive**: For App Store distribution

## Building the App

### Development Build
```bash
# Clean previous builds
xcodebuild clean -project FileOrganizer.xcodeproj -scheme FileOrganizer

# Build debug version
xcodebuild build -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Debug
```

### Release Build
```bash
# Build release version
xcodebuild build -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Release
```

### Find Built App
```bash
# Locate the built .app file
find ~/Library/Developer/Xcode/DerivedData -name "FileOrganizer.app" -type d
```

## Project Structure

### Core Files
```
FileOrganizer/
├── FileOrganizerApp.swift          # App entry point and menu bar
├── ContentView.swift               # Main tab navigation
├── Info.plist                      # App metadata and permissions
└── FileOrganizer.entitlements     # App sandbox permissions
```

### Models
```
Models/
├── ActivityLog.swift               # File operation logging
├── FileType.swift                  # File categorization
├── Preferences.swift               # User settings
└── InstallerTracker.swift         # Installer monitoring
```

### Services
```
Services/
├── FileOrganizer.swift             # Core organization logic
└── BookmarkManager.swift           # Secure folder access
```

### Views
```
Views/
├── DashboardView.swift             # Main interface
├── SettingsView.swift              # Configuration
├── PermissionRequestView.swift     # Initial setup
└── GlassBackground.swift           # UI styling
```

## Configuration

### App Sandbox Entitlements
The app uses macOS App Sandbox for security. Key entitlements:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.assets.pictures.read-write</key>
<true/>
<key>com.apple.security.assets.movies.read-write</key>
<true/>
<key>com.apple.security.assets.music.read-write</key>
<true/>
```

### File Type Support
Supported file extensions are defined in `FileType.swift`:

- **Documents**: pdf, docx, txt, rtf, md
- **Images**: jpg, jpeg, png, gif, heic, svg
- **Videos**: mp4, mov, avi, mkv
- **Music**: mp3, wav, flac, m4a
- **Archives**: zip, rar, 7z, tar, gz, bz2, xz
- **Installers**: dmg, pkg, app

## Testing

### Local Testing
1. **Build and Run**: Use Xcode's Run button (⌘+R)
2. **Test Permissions**: Verify Downloads folder access
3. **Test File Organization**: Download test files and observe behavior
4. **Check Logs**: Monitor Console app for debug output

### Debug Mode
Enable debug logging by running in debug configuration:
```bash
xcodebuild build -configuration Debug
```

### Console Logs
View detailed logs in Console app:
1. Open Console app
2. Filter by "FileOrganizer"
3. Monitor file operations and errors

## Distribution

### Development Distribution
```bash
# Build for development
xcodebuild archive -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Release -archivePath FileOrganizer.xcarchive

# Export for development
xcodebuild -exportArchive -archivePath FileOrganizer.xcarchive -exportPath ./ExportedApp -exportOptionsPlist exportOptions.plist
```

### App Store Distribution
1. **Archive**: Build archive in Xcode
2. **Validate**: Test with App Store Connect
3. **Upload**: Submit via Xcode or Application Loader

### Create DMG
```bash
# Install create-dmg if not available
brew install create-dmg

# Create DMG
create-dmg \
  --volname "File Organizer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "FileOrganizer.app" 200 190 \
  --hide-extension "FileOrganizer.app" \
  --app-drop-link 600 185 \
  "FileOrganizer.dmg" \
  "path/to/FileOrganizer.app"
```

## Troubleshooting

### Build Issues
```bash
# Clean build directory
xcodebuild clean -project FileOrganizer.xcodeproj -scheme FileOrganizer

# Reset derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Rebuild
xcodebuild build -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Debug
```

### Permission Issues
1. **Reset App Permissions**: System Preferences > Security & Privacy > Privacy
2. **Check Entitlements**: Verify entitlements file is correct
3. **Sandbox Issues**: Ensure all required entitlements are present

### Runtime Issues
1. **Check Console Logs**: Look for error messages
2. **Verify File Paths**: Ensure destination folders exist
3. **Test Permissions**: Verify folder access rights

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and test
xcodebuild build -configuration Debug

# Commit changes
git add .
git commit -m "Add new feature"

# Push and create PR
git push origin feature/new-feature
```

### 2. Testing
```bash
# Run tests (if available)
xcodebuild test -project FileOrganizer.xcodeproj -scheme FileOrganizer

# Build and test manually
xcodebuild build -configuration Debug
open /path/to/built/FileOrganizer.app
```

### 3. Code Quality
- Use Xcode's built-in analyzer
- Follow Swift style guidelines
- Add comments for complex logic
- Test on different macOS versions

## Performance Considerations

### File Monitoring
- Uses `DispatchSourceFileSystemObject` for efficient monitoring
- Periodic backup scanning every 10 seconds
- Debounced event processing (0.5s delay)

### Memory Management
- Activity logs are limited and auto-pruned
- File operations use background queues
- Efficient file type detection

### User Experience
- Non-blocking UI operations
- Progress indicators for bulk operations
- Responsive interface with proper state management

## Security Best Practices

### App Sandbox
- All file operations are sandboxed
- User must explicitly grant permissions
- No network access or data collection

### File Access
- Security-scoped bookmarks for persistent access
- User-selected folder access only
- No system folder modifications without permission

### Privacy
- All operations happen locally
- No telemetry or analytics
- User controls all data access

## Support and Resources

### Documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Guidelines](https://developer.apple.com/design/human-interface-guidelines/swiftui/)
- [macOS App Programming Guide](https://developer.apple.com/macos/)

### Community
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/swiftui)
- [GitHub Issues](https://github.com/username/FileOrganizer/issues)

---

This setup guide covers the essential aspects of developing, building, and distributing File Organizer. For additional help, refer to the main README or open an issue on GitHub.
