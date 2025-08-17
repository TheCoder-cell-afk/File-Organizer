//
//  BookmarkManager.swift
//  FileOrganizer
//
//  Created by Assistant on 8/16/25.
//

import Foundation

final class BookmarkManager {
    static let shared = BookmarkManager()
    private init() {}

    private let userDefaults = UserDefaults.standard
    private let bookmarkPrefix = "bookmark_"

    func saveBookmark(for fileType: FileType, url: URL) {
        do {
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            userDefaults.set(data, forKey: key(for: fileType))
        } catch {
            print("Failed to save bookmark for \(fileType): \(error)")
        }
    }

    func resolveURL(for fileType: FileType) -> URL? {
        guard let data = userDefaults.data(forKey: key(for: fileType)) else { return nil }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                // Refresh stale bookmark
                try refreshBookmark(for: fileType, url: url)
            }
            return url
        } catch {
            print("Failed to resolve bookmark for \(fileType): \(error)")
            return nil
        }
    }

    func startAccessing(for fileType: FileType) -> URL? {
        guard let url = resolveURL(for: fileType) else { return nil }
        _ = url.startAccessingSecurityScopedResource()
        return url
    }

    func stopAccessing(_ url: URL?) {
        url?.stopAccessingSecurityScopedResource()
    }

    private func key(for fileType: FileType) -> String {
        return bookmarkPrefix + fileType.rawValue
    }

    private func refreshBookmark(for fileType: FileType, url: URL) throws {
        let fresh = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        userDefaults.set(fresh, forKey: key(for: fileType))
    }
}


