//
//  MoveValidatorTests.swift
//  MeowdokuTests
//

import Testing
@testable import Meowdoku

struct MoveValidatorTests {
    private func makeBoard() -> Board {
        // 4x4, each column its own region.
        Board(size: 4, regions: [
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3],
        ])
    }

    @Test func isAdjacentCoversAllEightDirections() {
        let center = GridPosition(row: 1, col: 1)
        let neighbors = [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 2),
            GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1), GridPosition(row: 2, col: 2),
        ]
        for neighbor in neighbors {
            #expect(MoveValidator.isAdjacent(center, neighbor))
        }
        #expect(!MoveValidator.isAdjacent(center, GridPosition(row: 3, col: 3)))
        #expect(!MoveValidator.isAdjacent(center, center))
    }

    @Test func detectsRowConflict() {
        var board = makeBoard()
        board.placeCat(at: GridPosition(row: 0, col: 0))
        #expect(!MoveValidator.isLegal(placing: GridPosition(row: 0, col: 3), on: board))
    }

    @Test func detectsColumnConflict() {
        var board = makeBoard()
        board.placeCat(at: GridPosition(row: 0, col: 0))
        #expect(!MoveValidator.isLegal(placing: GridPosition(row: 3, col: 0), on: board))
    }

    @Test func detectsRegionConflict() {
        var board = makeBoard()
        board.placeCat(at: GridPosition(row: 0, col: 0))
        // Same region (column 0), far enough away to rule out row/column/adjacency.
        #expect(!MoveValidator.isLegal(placing: GridPosition(row: 2, col: 0), on: board))
    }

    @Test func detectsAdjacencyConflict() {
        var board = makeBoard()
        board.placeCat(at: GridPosition(row: 1, col: 1))
        #expect(!MoveValidator.isLegal(placing: GridPosition(row: 2, col: 2), on: board))
    }

    @Test func allowsNonConflictingPlacement() {
        var board = makeBoard()
        board.placeCat(at: GridPosition(row: 0, col: 0))
        #expect(MoveValidator.isLegal(placing: GridPosition(row: 2, col: 3), on: board))
    }

    @Test func ignoresTheCatBeingMoved() {
        var board = makeBoard()
        let position = GridPosition(row: 0, col: 0)
        board.placeCat(at: position)
        // A cat shouldn't conflict with itself when re-checking its own square.
        #expect(MoveValidator.isLegal(placing: position, on: board))
    }
}
