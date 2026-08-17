//
//  GameViewModel.swift
//  Meowdoku
//

import Combine
import SwiftUI

/// Owns the mutable board for the screen and translates player taps into
/// calls against the plain-Swift Core layer. No rule logic lives here.
@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var size: Int

    @Published private(set) var board: Board
    @Published private(set) var isSolved = false
    /// Cells the player has marked as "not a cat" - a deduction aid with no
    /// rule meaning, so it lives here rather than in the Core layer.
    @Published private(set) var markedCells: Set<GridPosition> = []

    private var solution: Set<GridPosition>

    init(puzzle: PuzzleGenerator.GeneratedPuzzle) {
        self.size = puzzle.size
        self.board = Board(size: puzzle.size, regions: puzzle.regions)
        self.solution = puzzle.solution
    }

    convenience init(size: Int = 6) {
        self.init(puzzle: PuzzleGenerator.generate(size: size)!)
    }

    func regionID(at position: GridPosition) -> Int {
        board.regionID(at: position)
    }

    func hasCat(at position: GridPosition) -> Bool {
        board.cats.contains(position)
    }

    func isMarked(at position: GridPosition) -> Bool {
        markedCells.contains(position)
    }

    /// A placed cat that conflicts with another placed cat (same row/column/region, or touching).
    func isConflicted(at position: GridPosition) -> Bool {
        hasCat(at: position) && !MoveValidator.isLegal(placing: position, on: board)
    }

    /// Single tap: toggle an X mark. Tapping a cat marks it instead of clearing
    /// it outright, since a mark means "decided this isn't a cat".
    func handleSingleTap(at position: GridPosition) {
        guard !isSolved else { return }
        if hasCat(at: position) {
            board.removeCat(at: position)
            markedCells.insert(position)
        } else if markedCells.contains(position) {
            markedCells.remove(position)
        } else {
            markedCells.insert(position)
        }
        isSolved = WinConditionChecker.isSolved(board)
    }

    /// Double tap: toggle a cat directly, clearing any mark on the way in.
    func handleDoubleTap(at position: GridPosition) {
        guard !isSolved else { return }
        if hasCat(at: position) {
            board.removeCat(at: position)
        } else {
            markedCells.remove(position)
            board.placeCat(at: position)
        }
        isSolved = WinConditionChecker.isSolved(board)
    }

    /// Reveals one correct cat placement the player hasn't found yet - the
    /// top-left-most missing solution cell, so the choice is deterministic
    /// rather than depending on `Set`'s unordered iteration.
    func requestHint() {
        guard !isSolved else { return }
        let missing = solution.subtracting(board.cats)
        guard let position = missing.min(by: { ($0.row, $0.col) < ($1.row, $1.col) }) else { return }
        markedCells.remove(position)
        board.placeCat(at: position)
        isSolved = WinConditionChecker.isSolved(board)
    }

    func newPuzzle() {
        newPuzzle(size: size)
    }

    /// Starts a fresh puzzle, optionally at a new board size. Valid sizes are
    /// 4 through 7 - below 4 no placement can satisfy the non-adjacency rule at
    /// all (exhaustive check for 2x2 and 3x3), and above 7 `PuzzleGenerator`'s
    /// random layout search stops reliably finding a unique-solution puzzle
    /// (measured empirically - see its doc comment), so the size picker never
    /// offers anything outside that range.
    func newPuzzle(size newSize: Int) {
        let puzzle = PuzzleGenerator.generate(size: newSize)!
        size = newSize
        board = Board(size: newSize, regions: puzzle.regions)
        solution = puzzle.solution
        markedCells = []
        isSolved = false
    }
}
