//
//  WinConditionCheckerTests.swift
//  MeowdokuTests
//

import Testing
@testable import Meowdoku

struct WinConditionCheckerTests {
    // 4x4, each column its own region, so a valid solve is any non-adjacent
    // column permutation.
    private func makeBoard() -> Board {
        Board(size: 4, regions: [
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3],
        ])
    }

    @Test func validSolutionIsSolved() {
        var board = makeBoard()
        for (row, col) in [(0, 1), (1, 3), (2, 0), (3, 2)] {
            board.placeCat(at: GridPosition(row: row, col: col))
        }
        #expect(WinConditionChecker.isSolved(board))
    }

    @Test func tooFewCatsIsNotSolved() {
        var board = makeBoard()
        board.placeCat(at: GridPosition(row: 0, col: 1))
        #expect(!WinConditionChecker.isSolved(board))
    }

    @Test func duplicateRowIsNotSolved() {
        var board = makeBoard()
        for (row, col) in [(0, 0), (0, 2), (2, 1), (3, 3)] {
            board.placeCat(at: GridPosition(row: row, col: col))
        }
        #expect(!WinConditionChecker.isSolved(board))
    }

    @Test func duplicateColumnIsNotSolved() {
        var board = makeBoard()
        for (row, col) in [(0, 0), (1, 2), (2, 0), (3, 3)] {
            board.placeCat(at: GridPosition(row: row, col: col))
        }
        #expect(!WinConditionChecker.isSolved(board))
    }

    @Test func adjacentCatsAreNotSolved() {
        // One region per row, so row/column/region coverage all pass and only
        // the adjacency rule is left to fail: (0,0) and (1,1) touch diagonally.
        var board = Board(size: 4, regions: [
            [0, 0, 0, 0],
            [1, 1, 1, 1],
            [2, 2, 2, 2],
            [3, 3, 3, 3],
        ])
        for (row, col) in [(0, 0), (1, 1), (2, 3), (3, 2)] {
            board.placeCat(at: GridPosition(row: row, col: col))
        }
        #expect(!WinConditionChecker.isSolved(board))
    }

    @Test func missingRegionCoverageIsNotSolved() {
        // All four cats land in only two of the four regions.
        var board = Board(size: 4, regions: [
            [0, 0, 1, 1],
            [0, 0, 1, 1],
            [0, 0, 1, 1],
            [0, 0, 1, 1],
        ])
        for (row, col) in [(0, 1), (1, 3), (2, 0), (3, 2)] {
            board.placeCat(at: GridPosition(row: row, col: col))
        }
        #expect(!WinConditionChecker.isSolved(board))
    }
}
