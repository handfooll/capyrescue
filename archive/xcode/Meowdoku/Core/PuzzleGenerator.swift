//
//  PuzzleGenerator.swift
//  Meowdoku
//

/// Generates playable puzzles: a random valid solution, then an irregular
/// region layout grown outward from that solution, retried until
/// `PuzzleSolver` confirms the layout admits exactly one solution.
enum PuzzleGenerator {
    struct GeneratedPuzzle {
        let size: Int
        let regions: [[Int]]
        let solution: Set<GridPosition>
    }

    /// - Parameter maxAttempts: each attempt generates a fresh random solution and region
    ///   layout; region growth is randomized, so a layout grown around a valid solution can
    ///   still end up admitting more than one, in which case we discard it and retry. The
    ///   odds of a random layout landing on a unique solution collapse as `size` grows -
    ///   measured empirically at size 6, size 7, and size 8 with 30 seeds each: size 6 is
    ///   reliable at 500, size 7 needs ~10000 to be reliable, and size 8 only succeeds
    ///   ~15% of the time even at 10000 (worth knowing before offering size 8+ in any UI:
    ///   raising this default further won't fix it - that needs a smarter algorithm).
    static func generate<R: RandomNumberGenerator>(
        size: Int,
        maxAttempts: Int = 10000,
        using rng: inout R
    ) -> GeneratedPuzzle? {
        for _ in 0..<maxAttempts {
            guard let solution = generateSolution(size: size, rng: &rng) else { continue }
            let regions = growRegions(size: size, solution: solution, rng: &rng)
            guard PuzzleSolver.hasUniqueSolution(size: size, regions: regions) else { continue }
            return GeneratedPuzzle(size: size, regions: regions, solution: Set(solution))
        }
        return nil
    }

    static func generate(size: Int, maxAttempts: Int = 10000) -> GeneratedPuzzle? {
        var rng = SystemRandomNumberGenerator()
        return generate(size: size, maxAttempts: maxAttempts, using: &rng)
    }

    /// One cat per row, satisfying the column and adjacency rules (region constraint
    /// is trivially satisfied once regions are grown one-per-solution-cell below).
    private static func generateSolution<R: RandomNumberGenerator>(
        size: Int,
        rng: inout R
    ) -> [GridPosition]? {
        var placed: [GridPosition] = []
        var usedColumns = Set<Int>()

        func backtrack(row: Int) -> Bool {
            if row == size { return true }
            for col in (0..<size).shuffled(using: &rng) {
                guard !usedColumns.contains(col) else { continue }
                let position = GridPosition(row: row, col: col)
                guard !placed.contains(where: { MoveValidator.isAdjacent($0, position) }) else { continue }
                placed.append(position)
                usedColumns.insert(col)
                if backtrack(row: row + 1) { return true }
                placed.removeLast()
                usedColumns.remove(col)
            }
            return false
        }

        return backtrack(row: 0) ? placed : nil
    }

    /// Multi-source randomized flood fill: each solution cell seeds one region, and
    /// regions take turns claiming a random unclaimed orthogonal neighbor from their
    /// frontier until every cell on the board belongs to exactly one region.
    private static func growRegions<R: RandomNumberGenerator>(
        size: Int,
        solution: [GridPosition],
        rng: inout R
    ) -> [[Int]] {
        var regionOf = Array(repeating: Array(repeating: -1, count: size), count: size)
        var frontiers: [[GridPosition]] = solution.map { [$0] }
        for (id, position) in solution.enumerated() {
            regionOf[position.row][position.col] = id
        }
        var remaining = size * size - solution.count

        while remaining > 0 {
            let growable = frontiers.indices.filter { !frontiers[$0].isEmpty }
            guard let regionID = growable.randomElement(using: &rng) else { break }
            let index = Int.random(in: frontiers[regionID].indices, using: &rng)
            let cell = frontiers[regionID].remove(at: index)

            for neighbor in cell.orthogonalNeighbors(within: size) where regionOf[neighbor.row][neighbor.col] == -1 {
                regionOf[neighbor.row][neighbor.col] = regionID
                frontiers[regionID].append(neighbor)
                remaining -= 1
            }
        }

        return regionOf
    }
}
