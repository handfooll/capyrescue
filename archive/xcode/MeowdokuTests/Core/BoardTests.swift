//
//  BoardTests.swift
//  MeowdokuTests
//

import Testing
@testable import Meowdoku

struct BoardTests {
    private func makeBoard() -> Board {
        // 3x3, three columns as regions.
        Board(size: 3, regions: [[0, 1, 2], [0, 1, 2], [0, 1, 2]])
    }

    @Test func containsRespectsBounds() {
        let board = makeBoard()
        #expect(board.contains(GridPosition(row: 0, col: 0)))
        #expect(board.contains(GridPosition(row: 2, col: 2)))
        #expect(!board.contains(GridPosition(row: 3, col: 0)))
        #expect(!board.contains(GridPosition(row: 0, col: -1)))
    }

    @Test func regionIDLooksUpTheRegionsGrid() {
        let board = makeBoard()
        #expect(board.regionID(at: GridPosition(row: 1, col: 2)) == 2)
    }

    @Test func placeAndRemoveCat() {
        var board = makeBoard()
        let position = GridPosition(row: 0, col: 1)
        board.placeCat(at: position)
        #expect(board.cats.contains(position))
        board.removeCat(at: position)
        #expect(!board.cats.contains(position))
    }

    @Test func toggleCat() {
        var board = makeBoard()
        let position = GridPosition(row: 1, col: 1)
        board.toggleCat(at: position)
        #expect(board.cats.contains(position))
        board.toggleCat(at: position)
        #expect(!board.cats.contains(position))
    }
}
