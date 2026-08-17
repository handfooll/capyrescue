//
//  CellView.swift
//  Meowdoku
//

import SwiftUI

/// A single board square: its region color, and a cat glyph when occupied.
struct CellView: View {
    let color: Color
    let hasCat: Bool
    let isMarked: Bool
    let isConflicted: Bool

    var body: some View {
        ZStack {
            color.opacity(0.55)
            if hasCat {
                Image(systemName: "cat.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .foregroundStyle(isConflicted ? .red : .primary)
                    // Decorative - the cell's own accessibilityLabel below is
                    // what UI tests and VoiceOver actually read.
                    .accessibilityHidden(true)
            } else if isMarked {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(Rectangle().stroke(.black.opacity(0.25), lineWidth: 1))
        .accessibilityLabel(accessibilityStateLabel)
    }

    private var accessibilityStateLabel: String {
        if hasCat { return isConflicted ? "cat, conflict" : "cat" }
        if isMarked { return "marked" }
        return "empty"
    }
}
