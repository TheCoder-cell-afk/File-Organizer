//
//  GlassBackground.swift
//  FileOrganizer
//
//  Created by Assistant on 8/16/25.
//

import SwiftUI
import AppKit

struct GlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .behindWindow
        v.state = .active
        v.isEmphasized = true
        v.wantsLayer = true
        v.layer?.cornerRadius = 12
        v.layer?.masksToBounds = true
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

extension View {
    func tahoeGlassBackground(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(
                ZStack {
                    GlassBackground()
                    LinearGradient(colors: [Color.white.opacity(0.08), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}


