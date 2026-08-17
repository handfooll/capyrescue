//
//  Board.swift
//  Meowdoku
//

/// The NxN grid, its region layout, and the cats currently placed on it.
///
/// This type owns no rule logic beyond bounds/region lookups - validation and
/// win checking live in `MoveValidator` and `WinConditionChecker` so the rules
/// stay independently testable.
struct Board {
    let size: Int
    /// `regions[row][col]` is the region id that cell belongs to.
    let regions: [[Int]]
    private(set) var cats: Set<GridPosition>

    init(size: Int, regions: [[Int]], cats: Set<GridPosition> = []) {
        precondition(regions.count == size, "regions must have `size` rows")
        precondition(regions.allSatisfy { $0.count == size }, "regions must have `size` columns")
        self.size = size
        self.regions = regions
        self.cats = cats
    }

    func contains(_ position: GridPosition) -> Bool {
        (0..<size).contains(position.row) && (0..<size).contains(position.col)
    }

    func regionID(at position: GridPosition) -> Int {
        regions[position.row][position.col]
    }

    mutating func placeCat(at position: GridPosition) {
        cats.insert(position)
    }

    mutating func removeCat(at position: GridPosition) {
        cats.remove(position)
    }

    mutating func toggleCat(at position: GridPosition) {
        if cats.contains(position) {
            cats.remove(position)
        } else {
            cats.insert(position)
        }
    }
}
