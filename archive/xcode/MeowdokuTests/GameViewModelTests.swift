//
//  GameViewModelTests.swift
//  MeowdokuTests
//

import Testing
@testable import Meowdoku

@MainActor
struct GameViewModelTests {
    // A trivial 1x1 puzzle with a known solution, so solving it is deterministic.
    private func makeTrivialViewModel() -> GameViewModel {
        let puzzle = PuzzleGenerator.GeneratedPuzzle(
            size: 1,
            regions: [[0]],
            solution: [GridPosition(row: 0, col: 0)]
        )
        return GameViewModel(puzzle: puzzle)
    }

    @Test func doubleTapSolvesTheTrivialBoard() {
        let viewModel = makeTrivialViewModel()
        let position = GridPosition(row: 0, col: 0)

        #expect(!viewModel.isSolved)
        viewModel.handleDoubleTap(at: position)
        #expect(viewModel.isSolved)
        #expect(viewModel.hasCat(at: position))
    }

    @Test func boardIgnoresTapsOnceSolved() {
        let viewModel = makeTrivialViewModel()
        let position = GridPosition(row: 0, col: 0)
        viewModel.handleDoubleTap(at: position)
        #expect(viewModel.isSolved)

        // A further double tap would normally remove the cat - it shouldn't once solved.
        viewModel.handleDoubleTap(at: position)
        #expect(viewModel.hasCat(at: position))
        #expect(viewModel.isSolved)

        // Nor should a single tap be able to sneak in a mark.
        viewModel.handleSingleTap(at: position)
        #expect(!viewModel.isMarked(at: position))
        #expect(viewModel.hasCat(at: position))
    }

    @Test func newPuzzleUnlocksTheBoard() {
        let viewModel = makeTrivialViewModel()
        let position = GridPosition(row: 0, col: 0)
        viewModel.handleDoubleTap(at: position)
        #expect(viewModel.isSolved)

        viewModel.newPuzzle()
        #expect(!viewModel.isSolved)

        viewModel.handleSingleTap(at: position)
        #expect(viewModel.isMarked(at: position))
    }

    // One region per row, with a hand-verified solution (see PuzzleSolverTests),
    // so hints have more than one cell to reveal in a known, deterministic order.
    private func makeFourByFourViewModel() -> GameViewModel {
        let regions = [[0, 0, 0, 0], [1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]
        let solution: Set<GridPosition> = [
            GridPosition(row: 0, col: 1),
            GridPosition(row: 1, col: 3),
            GridPosition(row: 2, col: 0),
            GridPosition(row: 3, col: 2),
        ]
        let puzzle = PuzzleGenerator.GeneratedPuzzle(size: 4, regions: regions, solution: solution)
        return GameViewModel(puzzle: puzzle)
    }

    @Test func hintRevealsOneCorrectCatAtATime() {
        let viewModel = makeFourByFourViewModel()
        #expect(viewModel.board.cats.isEmpty)

        viewModel.requestHint()
        #expect(viewModel.board.cats == [GridPosition(row: 0, col: 1)])
        #expect(!viewModel.isSolved)

        viewModel.requestHint()
        viewModel.requestHint()
        viewModel.requestHint()
        #expect(viewModel.board.cats.count == 4)
        #expect(viewModel.isSolved)
    }

    @Test func hintIsNoOpOnceSolved() {
        let viewModel = makeFourByFourViewModel()
        for _ in 0..<4 { viewModel.requestHint() }
        #expect(viewModel.isSolved)

        viewModel.requestHint()
        #expect(viewModel.board.cats.count == 4)
    }

    @Test func hintClearsAnyMarkOnThatCell() {
        let viewModel = makeFourByFourViewModel()
        let firstHintPosition = GridPosition(row: 0, col: 1)
        viewModel.handleSingleTap(at: firstHintPosition)
        #expect(viewModel.isMarked(at: firstHintPosition))

        viewModel.requestHint()
        #expect(!viewModel.isMarked(at: firstHintPosition))
        #expect(viewModel.hasCat(at: firstHintPosition))
    }

    @Test func newPuzzleWithSizeSwitchesBoardDimensions() {
        let viewModel = makeTrivialViewModel()
        #expect(viewModel.size == 1)

        viewModel.newPuzzle(size: 5)
        #expect(viewModel.size == 5)
        #expect(viewModel.board.size == 5)
        #expect(viewModel.board.cats.isEmpty)
    }

    @Test func newPuzzleWithSizeResetsProgressAndUnlocksAnAlreadySolvedBoard() {
        let viewModel = makeFourByFourViewModel()
        for _ in 0..<4 { viewModel.requestHint() }
        #expect(viewModel.isSolved)

        viewModel.newPuzzle(size: 6)
        #expect(viewModel.size == 6)
        #expect(!viewModel.isSolved)
        #expect(viewModel.board.cats.isEmpty)
    }
}
