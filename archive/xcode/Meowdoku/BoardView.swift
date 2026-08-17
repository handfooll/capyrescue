//
//  BoardView.swift
//  Meowdoku
//

import SwiftUI

/// Renders the full NxN grid and turns cell taps into `GameViewModel` calls.
struct BoardView: View {
    @ObservedObject var viewModel: GameViewModel

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 2), count: viewModel.size)
    }

    var body: some View {
        // A single flat ForEach, not nested row/col ForEach - two nested ForEach
        // ranges sharing the same 0..<size ids confuse LazyVGrid's diffing and
        // it silently drops every row past the first.
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<(viewModel.size * viewModel.size), id: \.self) { index in
                let position = GridPosition(row: index / viewModel.size, col: index % viewModel.size)
                CellView(
                    color: RegionPalette.color(for: viewModel.regionID(at: position)),
                    hasCat: viewModel.hasCat(at: position),
                    isMarked: viewModel.isMarked(at: position),
                    isConflicted: viewModel.isConflicted(at: position)
                )
                // A plain-color cell with no cat has no text/image content, so SwiftUI
                // gives it no accessibility presence by default - force it into one
                // element so XCUITest (and VoiceOver) can address it at all.
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("cell-\(position.row)-\(position.col)")
                // .exclusively(before:) makes the double-tap try first and only
                // fall through to the single-tap on failure - two independent
                // .onTapGesture(count:) modifiers don't reliably disambiguate.
                .gesture(
                    TapGesture(count: 2)
                        .onEnded { viewModel.handleDoubleTap(at: position) }
                        .exclusively(before: TapGesture(count: 1)
                            .onEnded { viewModel.handleSingleTap(at: position) }
                        )
                )
            }
        }
    }
}

#Preview {
    BoardView(viewModel: GameViewModel())
        .padding()
}
