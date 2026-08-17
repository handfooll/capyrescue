using NUnit.Framework;
using Meowdoku.Core;

namespace Meowdoku.Tests
{
    public class BoardValidatorTests
    {
        private static GridManager CreateGrid(int size, int[,] regions = null)
        {
            var grid = new GridManager(size);
            if (regions != null)
                grid.SetRegions(regions);
            return grid;
        }

        [Test]
        public void CheckRows_NoCats_ReturnsEmpty()
        {
            var grid = CreateGrid(4);
            var validator = new BoardValidator(grid);

            Assert.IsEmpty(validator.CheckRows());
        }

        [Test]
        public void CheckRows_TwoCatsSameRow_ReturnsBoth()
        {
            var grid = CreateGrid(4);
            grid.SetCellState(0, 0, CellState.Cat);
            grid.SetCellState(0, 3, CellState.Cat);
            var validator = new BoardValidator(grid);

            var conflicts = validator.CheckRows();

            Assert.AreEqual(2, conflicts.Count);
        }

        [Test]
        public void CheckColumns_TwoCatsSameColumn_ReturnsBoth()
        {
            var grid = CreateGrid(4);
            grid.SetCellState(0, 1, CellState.Cat);
            grid.SetCellState(3, 1, CellState.Cat);
            var validator = new BoardValidator(grid);

            var conflicts = validator.CheckColumns();

            Assert.AreEqual(2, conflicts.Count);
        }

        [Test]
        public void CheckRegions_TwoCatsSameRegion_ReturnsBoth()
        {
            var regions = new int[,]
            {
                { 0, 0 },
                { 1, 1 },
            };
            var grid = CreateGrid(2, regions);
            grid.SetCellState(0, 0, CellState.Cat);
            grid.SetCellState(0, 1, CellState.Cat);
            var validator = new BoardValidator(grid);

            var conflicts = validator.CheckRegions();

            Assert.AreEqual(2, conflicts.Count);
        }

        [Test]
        public void CheckAdjacency_OrthogonalNeighbors_ReturnsBoth()
        {
            var grid = CreateGrid(4);
            grid.SetCellState(1, 1, CellState.Cat);
            grid.SetCellState(1, 2, CellState.Cat);
            var validator = new BoardValidator(grid);

            var conflicts = validator.CheckAdjacency();

            Assert.AreEqual(2, conflicts.Count);
        }

        [Test]
        public void CheckAdjacency_DiagonalNeighbors_ReturnsBoth()
        {
            var grid = CreateGrid(4);
            grid.SetCellState(1, 1, CellState.Cat);
            grid.SetCellState(2, 2, CellState.Cat);
            var validator = new BoardValidator(grid);

            var conflicts = validator.CheckAdjacency();

            Assert.AreEqual(2, conflicts.Count);
        }

        [Test]
        public void CheckAdjacency_NonAdjacentCats_ReturnsEmpty()
        {
            var grid = CreateGrid(4);
            grid.SetCellState(0, 0, CellState.Cat);
            grid.SetCellState(3, 3, CellState.Cat);
            var validator = new BoardValidator(grid);

            Assert.IsEmpty(validator.CheckAdjacency());
        }

        [Test]
        public void Validate_CleanBoard_IsValid()
        {
            var regions = new int[,]
            {
                { 0, 0, 1, 1 },
                { 0, 0, 1, 1 },
                { 2, 2, 3, 3 },
                { 2, 2, 3, 3 },
            };
            var grid = CreateGrid(4, regions);
            grid.SetCellState(0, 0, CellState.Cat);
            grid.SetCellState(2, 2, CellState.Cat);
            var validator = new BoardValidator(grid);

            var result = validator.Validate();

            Assert.IsTrue(result.IsValid);
        }

        [Test]
        public void Validate_WithConflict_IsNotValid()
        {
            var grid = CreateGrid(4);
            grid.SetCellState(0, 0, CellState.Cat);
            grid.SetCellState(0, 1, CellState.Cat);
            var validator = new BoardValidator(grid);

            var result = validator.Validate();

            Assert.IsFalse(result.IsValid);
        }
    }
}
