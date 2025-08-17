# Changelog

All notable changes to File Organizer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial open source release
- Comprehensive documentation
- Contributing guidelines
- Setup instructions

## [1.0.0] - 2025-08-17

### Added
- **Core File Organization**: Automatic categorization and movement of downloaded files
- **Real-time Monitoring**: File system monitoring with DispatchSourceFileSystemObject
- **Smart File Detection**: Support for documents, images, videos, music, archives, and installers
- **User Control**: Manual organization options with individual and bulk actions
- **Revert System**: Comprehensive undo functionality for file moves
- **Menu Bar Integration**: Always-visible monitoring status indicator
- **Activity Logging**: Detailed log of all file operations
- **Installer Tracking**: Automatic cleanup of unused installer files
- **Settings Management**: Customizable destination folders and preferences
- **Permission Management**: Secure folder access with user consent
- **Refresh Capability**: Manual rescanning of Downloads folder

### Features
- **File Categories**:
  - Documents: PDF, DOCX, TXT, RTF, MD → `~/Downloads/Documents`
  - Images: JPG, JPEG, PNG, GIF, HEIC, SVG → `~/Downloads/Images`
  - Videos: MP4, MOV, AVI, MKV → `~/Downloads/Videos`
  - Music: MP3, WAV, FLAC, M4A → `~/Downloads/Music`
  - Archives: ZIP, RAR, 7Z, TAR, GZ, BZ2, XZ → `~/Downloads/Archives`
  - Installers: DMG, PKG, APP → `~/Downloads/Junk Installers` (after use)
  - Misc: Other files → `~/Downloads/Misc`

- **Organization Modes**:
  - **Automatic**: New downloads organized immediately (with optional confirmation)
  - **Manual**: Existing files marked as "Pending" for user organization
  - **Bulk Actions**: Organize all pending files or revert all moves
  - **Individual Control**: Organize or revert specific files

- **User Experience**:
  - Modern SwiftUI interface with macOS design guidelines
  - Liquid glass visual effects
  - Responsive design with proper state management
  - Non-blocking operations with background processing
  - Comprehensive error handling and user feedback

- **Security & Privacy**:
  - macOS App Sandbox compliance
  - Security-scoped bookmarks for persistent access
  - User-controlled permissions and folder access
  - No data collection or network transmission
  - Local-only file operations

### Technical Implementation
- **Architecture**: MVVM pattern with proper separation of concerns
- **File Monitoring**: Efficient file system event handling with debouncing
- **Memory Management**: Proper resource cleanup and weak references
- **Error Handling**: Comprehensive error logging and user feedback
- **Performance**: Optimized file operations and background processing
- **Compatibility**: macOS 13.0+ with modern Swift features

### Dependencies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **FileManager**: Native file system operations
- **DispatchSource**: Efficient file system monitoring
- **NSWorkspace**: Application launch detection
- **UserNotifications**: System notification support

## [Pre-Release] - Development Phase

### Development Milestones
- ✅ Basic file organization logic
- ✅ File system monitoring implementation
- ✅ User interface development
- ✅ Permission and security implementation
- ✅ Installer tracking and cleanup
- ✅ Activity logging system
- ✅ Settings and preferences management
- ✅ Manual organization controls
- ✅ Revert functionality
- ✅ Menu bar integration
- ✅ Error handling and user feedback
- ✅ Performance optimizations
- ✅ Security and privacy features
- ✅ Documentation and setup guides

### Technical Improvements
- Enhanced file monitoring reliability
- Improved error handling and logging
- Better user experience and interface design
- Comprehensive testing and bug fixes
- Performance optimizations
- Security enhancements

---

## Version History

- **1.0.0**: Initial stable release with all core features
- **Pre-Release**: Development and testing phase
- **Unreleased**: Future features and improvements

## Contributing

Please open an issue or submit a pull request for any improvements.

## License

This project is open source and available under the [MIT License](LICENSE).
