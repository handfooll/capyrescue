//
//  PuzzleSolverTests.swift
//  MeowdokuTests
//

import Testing
@testable import Meowdoku

struct PuzzleSolverTests {
    @Test func singleCellBoardHasOneTrivialSolution() {
        let solutions = PuzzleSolver.findSolutions(size: 1, regions: [[0]])
        #expect(solutions == [[GridPosition(row: 0, col: 0)]])
        #expect(PuzzleSolver.hasUniqueSolution(size: 1, regions: [[0]]))
    }

    @Test func threeByThreeColumnRegionsHaveNoSolution() {
        // One cat per row/column/region with the adjacency rule leaves no
        // legal permutation on a 3x3 board - verified by hand.
        let regions = [[0, 1, 2], [0, 1, 2], [0, 1, 2]]
        let solutions = PuzzleSolver.findSolutions(size: 3, regions: regions, limit: 10)
        #expect(solutions.isEmpty)
        #expect(!PuzzleSolver.hasUniqueSolution(size: 3, regions: regions))
    }

    @Test func fourByFourRowRegionsHaveExactlyTwoSolutions() {
        // Each row is its own region, so this reduces to a plain column
        // permutation under the adjacency rule - verified by hand to have
        // exactly two solutions: (1,3,0,2) and (2,0,3,1).
        let regions = [[0, 0, 0, 0], [1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]
        let solutions = PuzzleSolver.findSolutions(size: 4, regions: regions, limit: 10)

        let expected: Set<Set<GridPosition>> = [
            [GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 3), GridPosition(row: 2, col: 0), GridPosition(row: 3, col: 2)],
            [GridPosition(row: 0, col: 2), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 3), GridPosition(row: 3, col: 1)],
        ]
        #expect(Set(solutions) == expected)
        #expect(!PuzzleSolver.hasUniqueSolution(size: 4, regions: regions))
    }

    @Test func solverStopsAtLimit() {
        let regions = [[0, 0, 0, 0], [1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]
        let solutions = PuzzleSolver.findSolutions(size: 4, regions: regions, limit: 1)
        #expect(solutions.count == 1)
    }
}
