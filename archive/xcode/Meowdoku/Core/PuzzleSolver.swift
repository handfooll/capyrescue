//
//  PuzzleSolver.swift
//  Meowdoku
//

/// Brute-force backtracking solver over a fixed region layout.
///
/// This is intentionally independent of `PuzzleGenerator`'s own placement
/// logic: the generator uses it to confirm a layout has exactly one
/// solution, and every candidate it finds is cross-checked against
/// `WinConditionChecker` rather than trusted on the solver's own bookkeeping.
enum PuzzleSolver {
    /// Finds up to `limit` distinct solutions for the given region layout, placing
    /// one cat per row. Stops early once `limit` is reached.
    static func findSolutions(size: Int, regions: [[Int]], limit: Int = 2) -> [Set<GridPosition>] {
        var board = Board(size: size, regions: regions)
        var solutions: [Set<GridPosition>] = []

        func backtrack(row: Int) {
            if solutions.count >= limit { return }
            if row == size {
                if WinConditionChecker.isSolved(board) {
                    solutions.append(board.cats)
                }
                return
            }
            for col in 0..<size {
                if solutions.count >= limit { return }
                let position = GridPosition(row: row, col: col)
                guard MoveValidator.isLegal(placing: position, on: board) else { continue }
                board.placeCat(at: position)
                backtrack(row: row + 1)
                board.removeCat(at: position)
            }
        }

        backtrack(row: 0)
        return solutions
    }

    static func hasUniqueSolution(size: Int, regions: [[Int]]) -> Bool {
        findSolutions(size: size, regions: regions, limit: 2).count == 1
    }
}
