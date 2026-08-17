using System.Collections.Generic;
using NUnit.Framework;
using Meowdoku.Core;

namespace Meowdoku.Tests
{
    public class PuzzleGeneratorTests
    {
        [Test]
        public void Generate_SameSeed_IsDeterministic()
        {
            int[,] first = PuzzleGenerator.Generate(6, 12345);
            int[,] second = PuzzleGenerator.Generate(6, 12345);

            CollectionAssert.AreEqual(Flatten(first), Flatten(second));
        }

        [Test]
        public void Generate_DifferentSeeds_ProduceDifferentPuzzles()
        {
            int[,] a = PuzzleGenerator.Generate(6, 1);
            int[,] b = PuzzleGenerator.Generate(6, 2);

            CollectionAssert.AreNotEqual(Flatten(a), Flatten(b));
        }

        [TestCase(4)]
        [TestCase(5)]
        [TestCase(6)]
        public void Generate_CoversGridWithExactlyOneRegionIdPerIndex(int size)
        {
            int[,] regions = PuzzleGenerator.Generate(size, 999);

            var seen = new HashSet<int>();
            for (int r = 0; r < size; r++)
            {
                for (int c = 0; c < size; c++)
                {
                    int region = regions[r, c];
                    Assert.GreaterOrEqual(region, 0);
                    Assert.Less(region, size);
                    seen.Add(region);
                }
            }

            Assert.AreEqual(size, seen.Count);
        }

        [TestCase(6)]
        public void Generate_AllRegionsAreConnected(int size)
        {
            int[,] regions = PuzzleGenerator.Generate(size, 555);

            for (int regionId = 0; regionId < size; regionId++)
                Assert.IsTrue(IsRegionConnected(regions, size, regionId), $"Region {regionId} is not connected");
        }

        [TestCase(4)]
        [TestCase(5)]
        [TestCase(6)]
        public void Generate_HasExactlyOneSolution_VerifiedAgainstRealValidator(int size)
        {
            int[,] regions = PuzzleGenerator.Generate(size, 777);

            int solutionCount = CountRealSolutions(regions, size);

            Assert.AreEqual(1, solutionCount);
        }

        private static int[] Flatten(int[,] grid)
        {
            int rows = grid.GetLength(0);
            int cols = grid.GetLength(1);
            var flat = new int[rows * cols];
            int i = 0;
            for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                    flat[i++] = grid[r, c];
            return flat;
        }

        private static bool IsRegionConnected(int[,] regions, int size, int regionId)
        {
            var cells = new List<(int, int)>();
            for (int r = 0; r < size; r++)
                for (int c = 0; c < size; c++)
                    if (regions[r, c] == regionId)
                        cells.Add((r, c));

            if (cells.Count == 0)
                return false;

            var cellSet = new HashSet<(int, int)>(cells);
            var visited = new HashSet<(int, int)> { cells[0] };
            var stack = new Stack<(int, int)>();
            stack.Push(cells[0]);

            (int, int)[] deltas = { (1, 0), (-1, 0), (0, 1), (0, -1) };

            while (stack.Count > 0)
            {
                (int r, int c) = stack.Pop();
                foreach ((int dr, int dc) in deltas)
                {
                    var neighbor = (r + dr, c + dc);
                    if (cellSet.Contains(neighbor) && visited.Add(neighbor))
                        stack.Push(neighbor);
                }
            }

            return visited.Count == cells.Count;
        }

        // Brute-forces every one-cat-per-row/column permutation and checks it
        // against the actual game rules (BoardValidator + WinConditionChecker),
        // independent of PuzzleGenerator's own internal solver, so this catches
        // any drift between the generator's fast adjacency shortcut and the real
        // 8-directional adjacency check the game uses.
        private static int CountRealSolutions(int[,] regions, int size)
        {
            var columns = new int[size];
            for (int i = 0; i < size; i++)
                columns[i] = i;

            int count = 0;
            Permute(columns, 0, ref count, regions, size);
            return count;
        }

        private static void Permute(int[] columns, int start, ref int count, int[,] regions, int size)
        {
            if (start == columns.Length)
            {
                if (IsRealSolution(columns, regions, size))
                    count++;
                return;
            }

            for (int i = start; i < columns.Length; i++)
            {
                (columns[start], columns[i]) = (columns[i], columns[start]);
                Permute(columns, start + 1, ref count, regions, size);
                (columns[start], columns[i]) = (columns[i], columns[start]);
            }
        }

        private static bool IsRealSolution(int[] columns, int[,] regions, int size)
        {
            var grid = new GridManager(size);
            grid.SetRegions(regions);
            for (int row = 0; row < size; row++)
                grid.SetCellState(row, columns[row], CellState.Cat);

            var validator = new BoardValidator(grid);
            ValidationResult result = validator.Validate();
            return WinConditionChecker.IsSolved(grid, result);
        }
    }
}
