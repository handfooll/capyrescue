//
//  GridPosition.swift
//  Meowdoku
//

/// A single cell coordinate on the board, `(0, 0)` at the top-left.
struct GridPosition: Hashable {
    let row: Int
    let col: Int
}

extension GridPosition {
    /// The up-to-four orthogonally adjacent cells that fall within a `size x size` board.
    func orthogonalNeighbors(within size: Int) -> [GridPosition] {
        [
            GridPosition(row: row - 1, col: col),
            GridPosition(row: row + 1, col: col),
            GridPosition(row: row, col: col - 1),
            GridPosition(row: row, col: col + 1),
        ].filter { (0..<size).contains($0.row) && (0..<size).contains($0.col) }
    }
}
