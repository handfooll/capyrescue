//
//  RegionPalette.swift
//  Meowdoku
//

import SwiftUI

/// Maps a region id to a display color. Purely cosmetic - region identity
/// for rule purposes lives entirely in `Board.regions`.
enum RegionPalette {
    private static let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple, .pink, .brown,
    ]

    static func color(for regionID: Int) -> Color {
        colors[regionID % colors.count]
    }
}
