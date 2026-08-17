using System.Collections.Generic;
using System.Linq;

namespace Meowdoku.Core
{
    public class ValidationResult
    {
        public List<Cell> RowConflicts { get; } = new List<Cell>();
        public List<Cell> ColumnConflicts { get; } = new List<Cell>();
        public List<Cell> RegionConflicts { get; } = new List<Cell>();
        public List<Cell> AdjacencyConflicts { get; } = new List<Cell>();

        public IEnumerable<Cell> AllConflicts =>
            RowConflicts
                .Concat(ColumnConflicts)
                .Concat(RegionConflicts)
                .Concat(AdjacencyConflicts)
                .Distinct();

        public bool IsValid => !AllConflicts.Any();
    }

    public class BoardValidator
    {
        private readonly GridManager _gridManager;

        public BoardValidator(GridManager gridManager)
        {
            _gridManager = gridManager;
        }

        public ValidationResult Validate()
        {
            var result = new ValidationResult();

            result.RowConflicts.AddRange(CheckRows());
            result.ColumnConflicts.AddRange(CheckColumns());
            result.RegionConflicts.AddRange(CheckRegions());
            result.AdjacencyConflicts.AddRange(CheckAdjacency());

            return result;
        }

        public List<Cell> CheckRows()
        {
            var conflicts = new List<Cell>();
            int size = _gridManager.Size;

            for (int row = 0; row < size; row++)
            {
                var catsInRow = new List<Cell>();
                for (int col = 0; col < size; col++)
                {
                    var cell = _gridManager.GetCell(row, col);
                    if (cell.State == CellState.Cat)
                        catsInRow.Add(cell);
                }

                if (catsInRow.Count > 1)
                    conflicts.AddRange(catsInRow);
            }

            return conflicts;
        }

        public List<Cell> CheckColumns()
        {
            var conflicts = new List<Cell>();
            int size = _gridManager.Size;

            for (int col = 0; col < size; col++)
            {
                var catsInColumn = new List<Cell>();
                for (int row = 0; row < size; row++)
                {
                    var cell = _gridManager.GetCell(row, col);
                    if (cell.State == CellState.Cat)
                        catsInColumn.Add(cell);
                }

                if (catsInColumn.Count > 1)
                    conflicts.AddRange(catsInColumn);
            }

            return conflicts;
        }

        public List<Cell> CheckRegions()
        {
            var conflicts = new List<Cell>();
            var catsByRegion = new Dictionary<int, List<Cell>>();
            int size = _gridManager.Size;

            for (int row = 0; row < size; row++)
            {
                for (int col = 0; col < size; col++)
                {
                    var cell = _gridManager.GetCell(row, col);
                    if (cell.State != CellState.Cat)
                        continue;

                    if (!catsByRegion.TryGetValue(cell.RegionId, out var regionCats))
                    {
                        regionCats = new List<Cell>();
                        catsByRegion[cell.RegionId] = regionCats;
                    }

                    regionCats.Add(cell);
                }
            }

            foreach (var regionCats in catsByRegion.Values)
            {
                if (regionCats.Count > 1)
                    conflicts.AddRange(regionCats);
            }

            return conflicts;
        }

        public List<Cell> CheckAdjacency()
        {
            var conflicts = new HashSet<Cell>();
            int size = _gridManager.Size;

            for (int row = 0; row < size; row++)
            {
                for (int col = 0; col < size; col++)
                {
                    var cell = _gridManager.GetCell(row, col);
                    if (cell.State != CellState.Cat)
                        continue;

                    for (int dRow = -1; dRow <= 1; dRow++)
                    {
                        for (int dCol = -1; dCol <= 1; dCol++)
                        {
                            if (dRow == 0 && dCol == 0)
                                continue;

                            int neighborRow = row + dRow;
                            int neighborCol = col + dCol;

                            if (!_gridManager.IsInBounds(neighborRow, neighborCol))
                                continue;

                            var neighbor = _gridManager.GetCell(neighborRow, neighborCol);
                            if (neighbor.State == CellState.Cat)
                            {
                                conflicts.Add(cell);
                                conflicts.Add(neighbor);
                            }
                        }
                    }
                }
            }

            return conflicts.ToList();
        }
    }
}
