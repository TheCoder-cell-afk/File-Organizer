# File Organizer

A macOS app built with SwiftUI that automatically organizes your Downloads folder by categorizing files and moving them to appropriate destination folders.

## Features

### 🚀 **Automatic File Organization**
- **Real-time Monitoring**: Watches your Downloads folder for new files
- **Smart Categorization**: Automatically detects file types and organizes them
- **Custom Destinations**: Configurable folder paths for each file category

### 📁 **File Categories**
- **Documents**: PDF, DOCX, TXT, RTF, MD → `~/Downloads/Documents`
- **Images**: JPG, JPEG, PNG, GIF, HEIC, SVG → `~/Downloads/Images`
- **Videos**: MP4, MOV, AVI, MKV → `~/Downloads/Videos`
- **Music**: MP3, WAV, FLAC, M4A → `~/Downloads/Music`
- **Archives**: ZIP, RAR, 7Z, TAR, GZ → `~/Downloads/Archives`
- **Installers**: DMG, PKG, APP → `~/Downloads/Junk Installers` (after use)
- **Misc**: Other files → `~/Downloads/Misc`

### 🎛️ **User Control**
- **Manual Organization**: Organize existing files with individual or bulk actions
- **Confirmation Options**: Choose whether to confirm before moving new downloads
- **Revert Functionality**: Undo file moves with individual or bulk revert options
- **Refresh Capability**: Manually refresh Downloads folder scanning

### 🔧 **Advanced Features**
- **Installer Tracking**: Monitors installer usage and cleans up unused files
- **Menu Bar Status**: Always-visible monitoring status indicator
- **Background Operation**: Runs in background for continuous monitoring
- **Activity Logging**: Comprehensive log of all file operations

## Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

## Installation

### Option 1: Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/username/FileOrganizer.git
   cd FileOrganizer
   ```

2. **Open in Xcode**
   ```bash
   open FileOrganizer.xcodeproj
   ```

3. **Build and Run**
   - Select your target device (My Mac)
   - Press `Cmd + R` to build and run
   - Or use `Product > Run` from the menu

### Option 2: Command Line Build

1. **Navigate to project directory**
   ```bash
   cd FileOrganizer
   ```

2. **Build the project**
   ```bash
   xcodebuild build -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Release
   ```

3. **Find the built app**
   ```bash
   find ~/Library/Developer/Xcode/DerivedData -name "FileOrganizer.app" -type d
   ```

## Setup & Configuration

### First Launch
1. **Permission Request**: The app will ask for permission to access your Downloads folder
2. **Enable Monitoring**: Click "Enable File Organizer" to start automatic organization
3. **Grant Permissions**: macOS will request access to Downloads folder

### Settings Configuration
- **File Handling**: Toggle confirmation dialogs for new downloads
- **Custom Destinations**: Set custom folder paths for each file category
- **Installer Settings**: Configure grace periods and cleanup behavior

### Menu Bar Integration
- **Status Indicator**: Green circle = monitoring active, Red circle = stopped
- **Quick Access**: Click menu bar icon for status and quick actions

## Usage

### Automatic Organization
- Files downloaded from browsers are automatically organized
- Existing files in Downloads are marked as "Pending" for manual organization
- Use "Organize All Pending" to bulk organize existing files

### Manual Control
- **Individual Files**: Click "Organize" next to pending files
- **Bulk Actions**: Use "Organize All Pending" for multiple files
- **Refresh**: Click "Refresh" to rescan Downloads folder

### Reverting Changes
- **Individual Revert**: Click "Revert" next to moved files
- **Recent Reverts**: Use "Revert All Recent" for files moved in last 30 minutes
- **Complete Revert**: Use "Revert All Moved" for all organized files

## Architecture

### Project Structure
```
FileOrganizer/
├── FileOrganizerApp.swift          # Main app entry point
├── ContentView.swift               # Root view with tab navigation
├── Models/
│   ├── ActivityLog.swift          # File operation logging
│   ├── FileType.swift             # File categorization logic
│   ├── Preferences.swift          # User settings management
│   └── InstallerTracker.swift    # Installer usage tracking
├── Services/
│   ├── FileOrganizer.swift        # Core file organization logic
│   └── BookmarkManager.swift      # Security-scoped bookmark management
└── Views/
    ├── DashboardView.swift        # Main dashboard interface
    ├── SettingsView.swift         # Settings configuration
    ├── PermissionRequestView.swift # Initial permission request
    └── GlassBackground.swift      # UI styling components
```

### Key Components
- **FileOrganizer**: Core service managing file monitoring and organization
- **ActivityLog**: Comprehensive logging system for all operations
- **Preferences**: User settings and configuration management
- **BookmarkManager**: Secure folder access management

## Development

### Building for Development
```bash
xcodebuild build -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Debug
```

### Building for Release
```bash
xcodebuild build -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Release
```

### Clean Build
```bash
xcodebuild clean -project FileOrganizer.xcodeproj -scheme FileOrganizer
xcodebuild build -project FileOrganizer.xcodeproj -scheme FileOrganizer -configuration Debug
```

## Troubleshooting

### Common Issues

**App not detecting new downloads**
- Ensure the app has permission to access Downloads folder
- Check that monitoring is enabled in the dashboard
- Verify the app is running in the background

**Files not being organized**
- Check the activity log for error messages
- Verify destination folders exist and are accessible
- Ensure file extensions are supported

**Permission denied errors**
- Reset app permissions in System Preferences > Security & Privacy
- Re-grant access to Downloads folder when prompted

### Debug Information
- Check the Console app for detailed logs
- Review the in-app activity log for operation details
- Verify file paths and permissions in Settings

## Contributing

We welcome contributions! Please open an issue or submit a pull request for any improvements.

## Security & Privacy

- **Local Only**: All file operations happen locally on your machine
- **No Data Collection**: The app doesn't collect or transmit any personal data
- **Sandboxed**: Runs with macOS App Sandbox for enhanced security
- **Permission Based**: Only accesses folders you explicitly grant permission to

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

- **Issues**: Report bugs or request features via GitHub Issues

## Acknowledgments

- Built with SwiftUI and modern macOS development practices
- Leverages macOS file system monitoring and security features
- Designed for privacy and user control

---

**Note**: This app requires macOS 13.0 or later and appropriate permissions to function properly. Always review permissions before granting access to your file system.
