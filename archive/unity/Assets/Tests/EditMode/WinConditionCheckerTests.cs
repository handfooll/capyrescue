using NUnit.Framework;
using Meowdoku.Core;

namespace Meowdoku.Tests
{
    public class WinConditionCheckerTests
    {
        // Regions assigned by row so a diagonal placement (one cat per row/column)
        // also lands one cat per region, isolating these tests from BoardValidator.
        private static GridManager CreateDiagonalGrid(int size)
        {
            var grid = new GridManager(size);
            var regions = new int[size, size];
            for (int row = 0; row < size; row++)
                for (int col = 0; col < size; col++)
                    regions[row, col] = row;
            grid.SetRegions(regions);

            for (int i = 0; i < size; i++)
                grid.SetCellState(i, i, CellState.Cat);

            return grid;
        }

        [Test]
        public void IsSolved_OneCatPerRowColumnRegion_ReturnsTrue()
        {
            var grid = CreateDiagonalGrid(4);

            bool solved = WinConditionChecker.IsSolved(grid, new ValidationResult());

            Assert.IsTrue(solved);
        }

        [Test]
        public void IsSolved_ValidationResultInvalid_ReturnsFalse()
        {
            var grid = CreateDiagonalGrid(4);
            var invalidResult = new ValidationResult();
            invalidResult.RowConflicts.Add(grid.GetCell(0, 0));
            invalidResult.RowConflicts.Add(grid.GetCell(1, 1));

            bool solved = WinConditionChecker.IsSolved(grid, invalidResult);

            Assert.IsFalse(solved);
        }

        [Test]
        public void IsSolved_MissingCatInRow_ReturnsFalse()
        {
            var grid = new GridManager(4);
            grid.SetCellState(0, 0, CellState.Cat);
            grid.SetCellState(1, 1, CellState.Cat);
            grid.SetCellState(2, 2, CellState.Cat);
            // Row 3 has no cat.

            bool solved = WinConditionChecker.IsSolved(grid, new ValidationResult());

            Assert.IsFalse(solved);
        }

        [Test]
        public void IsSolved_TwoCatsShareRegion_ReturnsFalse()
        {
            var grid = CreateDiagonalGrid(3);
            // Force cells (0,0) and (1,1) into the same region despite being on
            // different rows/columns, so row/column counts stay valid but the
            // region count does not.
            grid.SetRegionId(1, 1, grid.GetCell(0, 0).RegionId);

            bool solved = WinConditionChecker.IsSolved(grid, new ValidationResult());

            Assert.IsFalse(solved);
        }

        [Test]
        public void IsSolved_EmptyBoard_ReturnsFalse()
        {
            var grid = new GridManager(4);

            bool solved = WinConditionChecker.IsSolved(grid, new ValidationResult());

            Assert.IsFalse(solved);
        }
    }
}
