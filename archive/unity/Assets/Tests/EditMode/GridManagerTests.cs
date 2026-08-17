using System;
using NUnit.Framework;
using Meowdoku.Core;

namespace Meowdoku.Tests
{
    public class GridManagerTests
    {
        [Test]
        public void Constructor_DefaultSize_CreatesAllCellsEmpty()
        {
            var grid = new GridManager();

            Assert.AreEqual(GridManager.DefaultSize, grid.Size);
            for (int row = 0; row < grid.Size; row++)
            {
                for (int col = 0; col < grid.Size; col++)
                {
                    Cell cell = grid.GetCell(row, col);
                    Assert.AreEqual(CellState.Empty, cell.State);
                    Assert.AreEqual(row, cell.Row);
                    Assert.AreEqual(col, cell.Column);
                }
            }
        }

        [TestCase(0)]
        [TestCase(-1)]
        public void Constructor_NonPositiveSize_Throws(int size)
        {
            Assert.Throws<ArgumentOutOfRangeException>(() => new GridManager(size));
        }

        [Test]
        public void GetCell_OutOfBounds_Throws()
        {
            var grid = new GridManager(4);

            Assert.Throws<ArgumentOutOfRangeException>(() => grid.GetCell(-1, 0));
            Assert.Throws<ArgumentOutOfRangeException>(() => grid.GetCell(0, 4));
        }

        [Test]
        public void SetCellState_UpdatesState()
        {
            var grid = new GridManager(4);

            grid.SetCellState(1, 2, CellState.Cat);

            Assert.AreEqual(CellState.Cat, grid.GetCell(1, 2).State);
        }

        [Test]
        public void SetRegions_WrongDimensions_Throws()
        {
            var grid = new GridManager(4);
            var wrongSize = new int[3, 3];

            Assert.Throws<ArgumentException>(() => grid.SetRegions(wrongSize));
        }

        [Test]
        public void SetRegions_ValidMap_AssignsRegionIds()
        {
            var grid = new GridManager(2);
            var regions = new int[,] { { 0, 1 }, { 1, 0 } };

            grid.SetRegions(regions);

            Assert.AreEqual(0, grid.GetCell(0, 0).RegionId);
            Assert.AreEqual(1, grid.GetCell(0, 1).RegionId);
            Assert.AreEqual(1, grid.GetCell(1, 0).RegionId);
            Assert.AreEqual(0, grid.GetCell(1, 1).RegionId);
        }

        [Test]
        public void ClearBoard_ResetsAllCellsToEmpty()
        {
            var grid = new GridManager(3);
            grid.SetCellState(0, 0, CellState.Cat);
            grid.SetCellState(1, 1, CellState.X);

            grid.ClearBoard();

            for (int row = 0; row < grid.Size; row++)
                for (int col = 0; col < grid.Size; col++)
                    Assert.AreEqual(CellState.Empty, grid.GetCell(row, col).State);
        }

        [Test]
        public void IsInBounds_ReflectsGridSize()
        {
            var grid = new GridManager(3);

            Assert.IsTrue(grid.IsInBounds(0, 0));
            Assert.IsTrue(grid.IsInBounds(2, 2));
            Assert.IsFalse(grid.IsInBounds(-1, 0));
            Assert.IsFalse(grid.IsInBounds(0, 3));
        }
    }
}
