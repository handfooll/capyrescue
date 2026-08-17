//
//  WinConditionChecker.swift
//  Meowdoku
//

/// Checks whether a board, as currently filled in, satisfies every win
/// condition: exactly one cat per row, column, and region, with no two cats
/// touching (including diagonally).
enum WinConditionChecker {
    static func isSolved(_ board: Board) -> Bool {
        guard board.cats.count == board.size else { return false }
        guard board.cats.allSatisfy(board.contains) else { return false }

        let rows = Set(board.cats.map(\.row))
        let columns = Set(board.cats.map(\.col))
        let regionIDs = Set(board.cats.map(board.regionID(at:)))
        guard rows.count == board.size, columns.count == board.size, regionIDs.count == board.size else {
            return false
        }

        let cats = Array(board.cats)
        for i in cats.indices {
            for j in cats.indices where j > i {
                if MoveValidator.isAdjacent(cats[i], cats[j]) {
                    return false
                }
            }
        }
        return true
    }
}
