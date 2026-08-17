//
//  MoveValidator.swift
//  Meowdoku
//

/// A reason a candidate cat placement conflicts with a cat already on the board.
enum MoveConflict: Hashable {
    case row(GridPosition)
    case column(GridPosition)
    case region(GridPosition)
    case adjacent(GridPosition)
}

/// Checks whether placing a cat at a given position is legal against the
/// cats already on the board - used for live feedback while the player plays,
/// independent of whether the full board is solved.
enum MoveValidator {
    /// All cats already on the board that would conflict with a cat placed at `position`.
    static func conflicts(placing position: GridPosition, on board: Board) -> [MoveConflict] {
        board.cats.filter { $0 != position }.compactMap { existing in
            if existing.row == position.row {
                return .row(existing)
            } else if existing.col == position.col {
                return .column(existing)
            } else if board.regionID(at: existing) == board.regionID(at: position) {
                return .region(existing)
            } else if isAdjacent(existing, position) {
                return .adjacent(existing)
            }
            return nil
        }
    }

    static func isLegal(placing position: GridPosition, on board: Board) -> Bool {
        conflicts(placing: position, on: board).isEmpty
    }

    /// Whether two cells touch horizontally, vertically, or diagonally.
    static func isAdjacent(_ a: GridPosition, _ b: GridPosition) -> Bool {
        a != b && abs(a.row - b.row) <= 1 && abs(a.col - b.col) <= 1
    }
}
