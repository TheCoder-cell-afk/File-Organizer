//
//  FileType.swift
//  FileOrganizer
//
//  
//

import Foundation

enum FileType: String, CaseIterable {
    case document = "Documents"
    case image = "Images"
    case video = "Videos"
    case music = "Music"
    case archive = "Archives"
    case installer = "Installers"
    case misc = "Misc"
    
    var extensions: [String] {
        switch self {
        case .document:
            return ["pdf", "docx", "doc", "txt", "rtf", "md", "odt", "xls", "xlsx", "ppt", "pptx"]
        case .image:
            return ["jpg", "jpeg", "png", "gif", "heic", "svg", "bmp", "tiff", "webp", "ico"]
        case .video:
            return ["mp4", "mov", "avi", "mkv", "webm", "flv", "wmv", "m4v", "mpg", "mpeg"]
        case .music:
            return ["mp3", "wav", "flac", "m4a", "aac", "ogg", "wma", "aiff", "alac"]
        case .archive:
            return ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"]
        case .installer:
            return ["dmg", "pkg", "app"]
        case .misc:
            return []
        }
    }
    
    var destinationPath: String {
        switch self {
        case .document:
            return "~/Downloads/Documents"
        case .image:
            return "~/Downloads/Images"
        case .video:
            return "~/Downloads/Videos"
        case .music:
            return "~/Downloads/Music"
        case .archive:
            return "~/Downloads/Archives"
        case .installer:
            return "~/Downloads/Junk Installers"
        case .misc:
            return "~/Downloads/Misc"
        }
    }
    
    static func from(fileExtension: String) -> FileType {
        let ext = fileExtension.lowercased()
        
        // Check each type's extensions
        for type in FileType.allCases {
            if type.extensions.contains(ext) {
                return type
            }
        }
        
        // If no specific type matches, return misc
        return .misc
    }
}

