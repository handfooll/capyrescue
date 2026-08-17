//
//  PuzzleGeneratorTests.swift
//  MeowdokuTests
//

import Testing
@testable import Meowdoku

/// Deterministic RNG so generator tests are reproducible.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xdead_beef : seed }
    mutating func next() -> UInt64 {
        // splitmix64
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct PuzzleGeneratorTests {
    /// Brute-force cross-check per the project's testing approach: don't just
    /// trust the generator's own solution, verify the emitted board against
    /// the actual win-condition validator and re-derive uniqueness with an
    /// independent solver.
    @Test(arguments: [4, 5, 6, 7], [1, 2, 3])
    func generatedPuzzleIsValidAndUnique(size: Int, seed: UInt64) {
        var rng = SeededGenerator(seed: seed)
        guard let puzzle = PuzzleGenerator.generate(size: size, using: &rng) else {
            Issue.record("generator failed to produce a puzzle for size \(size), seed \(seed)")
            return
        }

        #expect(puzzle.size == size)
        #expect(puzzle.regions.count == size)
        #expect(puzzle.regions.allSatisfy { $0.count == size })

        var board = Board(size: size, regions: puzzle.regions)
        for position in puzzle.solution {
            board.placeCat(at: position)
        }
        #expect(WinConditionChecker.isSolved(board))

        let solutions = PuzzleSolver.findSolutions(size: size, regions: puzzle.regions, limit: 2)
        #expect(solutions.count == 1)
        #expect(solutions.first == puzzle.solution)
    }

    @Test(arguments: [4, 5, 6, 7])
    func regionsPartitionTheBoardIntoExactlySizeConnectedTerritories(size: Int) {
        var rng = SeededGenerator(seed: 42)
        guard let puzzle = PuzzleGenerator.generate(size: size, using: &rng) else {
            Issue.record("generator failed to produce a puzzle for size \(size)")
            return
        }

        var cellsByRegion: [Int: [GridPosition]] = [:]
        for row in 0..<size {
            for col in 0..<size {
                cellsByRegion[puzzle.regions[row][col], default: []].append(GridPosition(row: row, col: col))
            }
        }

        #expect(cellsByRegion.keys.count == size)
        #expect(cellsByRegion.values.reduce(0) { $0 + $1.count } == size * size)

        for cells in cellsByRegion.values {
            #expect(isConnected(cells, size: size))
        }
    }

    /// Orthogonal-adjacency BFS connectivity check, independent of the generator's own growth logic.
    private func isConnected(_ cells: [GridPosition], size: Int) -> Bool {
        guard let start = cells.first else { return true }
        let cellSet = Set(cells)
        var visited: Set<GridPosition> = [start]
        var queue = [start]
        while let current = queue.popLast() {
            for neighbor in current.orthogonalNeighbors(within: size) where cellSet.contains(neighbor) && !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }
        return visited.count == cellSet.count
    }
}
