using System;
using System.Collections.Generic;

namespace Meowdoku.Core
{
    // Generates NxN region maps with a guaranteed, verified-unique solution
    // under the game's rules (one cat per row/column/region, no 8-directional
    // touching). Fully deterministic for a given (size, seed) pair, and has no
    // UnityEngine dependency so it can be unit tested directly.
    public static class PuzzleGenerator
    {
        private const int MaxOuterAttempts = 200;
        private const int MaxHillClimbIterations = 6000;
        private const int SolutionCountCap = 8;

        public static int[,] Generate(int size, int seed)
        {
            if (size < 2)
                throw new ArgumentOutOfRangeException(nameof(size), "Puzzle size must be at least 2.");

            var rng = new Random(seed);
            int minRegionSize = Math.Max(2, size / 2);
            int maxRegionSize = size + size; // average region size is `size`; allow up to double

            for (int attempt = 0; attempt < MaxOuterAttempts; attempt++)
            {
                int[] solution = GenerateSolutionPermutation(size, rng);
                int[,] regions = GrowRegions(solution, size, rng);
                if (regions == null)
                    continue;

                if (HillClimbToUnique(regions, solution, size, rng, minRegionSize, maxRegionSize))
                    return regions;
            }

            throw new InvalidOperationException(
                $"Failed to generate a {size}x{size} puzzle with a unique solution after {MaxOuterAttempts} attempts (seed {seed}).");
        }

        private static int[] GenerateSolutionPermutation(int size, Random rng)
        {
            var columns = new int[size];
            while (true)
            {
                for (int i = 0; i < size; i++)
                    columns[i] = i;

                for (int i = size - 1; i > 0; i--)
                {
                    int j = rng.Next(i + 1);
                    (columns[i], columns[j]) = (columns[j], columns[i]);
                }

                bool valid = true;
                for (int row = 0; row < size - 1; row++)
                {
                    if (Math.Abs(columns[row] - columns[row + 1]) <= 1)
                    {
                        valid = false;
                        break;
                    }
                }

                if (valid)
                    return columns;
            }
        }

        // Fills `buffer` (must have length >= 4) with in-bounds orthogonal neighbors
        // and returns how many were written. Avoids the per-call heap allocation an
        // IEnumerable/yield-return neighbor iterator would cost in these hot loops.
        private static int GetNeighbors(int r, int c, int size, (int, int)[] buffer)
        {
            int count = 0;
            if (r + 1 < size) buffer[count++] = (r + 1, c);
            if (r - 1 >= 0) buffer[count++] = (r - 1, c);
            if (c + 1 < size) buffer[count++] = (r, c + 1);
            if (c - 1 >= 0) buffer[count++] = (r, c - 1);
            return count;
        }

        private static int[,] GrowRegions(int[] solution, int size, Random rng)
        {
            var regions = new int[size, size];
            for (int r = 0; r < size; r++)
                for (int c = 0; c < size; c++)
                    regions[r, c] = -1;

            var frontier = new List<(int r, int c)>();
            for (int row = 0; row < size; row++)
            {
                regions[row, solution[row]] = row;
                frontier.Add((row, solution[row]));
            }

            int unclaimed = size * size - size;
            var neighborBuffer = new (int, int)[4];

            while (unclaimed > 0)
            {
                Shuffle(frontier, rng);
                var nextFrontier = new List<(int r, int c)>();
                bool progressed = false;

                foreach ((int r, int c) in frontier)
                {
                    int region = regions[r, c];
                    int neighborCount = GetNeighbors(r, c, size, neighborBuffer);
                    for (int i = 0; i < neighborCount; i++)
                    {
                        (int nr, int nc) = neighborBuffer[i];
                        if (regions[nr, nc] == -1)
                        {
                            regions[nr, nc] = region;
                            unclaimed--;
                            progressed = true;
                            nextFrontier.Add((nr, nc));
                        }
                    }

                    nextFrontier.Add((r, c));
                }

                frontier = nextFrontier;
                if (!progressed)
                    return null; // stuck; caller retries with a new solution
            }

            return regions;
        }

        private static void Shuffle<T>(IList<T> list, Random rng)
        {
            for (int i = list.Count - 1; i > 0; i--)
            {
                int j = rng.Next(i + 1);
                (list[i], list[j]) = (list[j], list[i]);
            }
        }

        // Scratch buffers below are sized size*size and reused across the whole
        // hill-climb run (allocated once by the caller) instead of allocating a
        // HashSet/Stack per call - this runs thousands of times per attempt.
        private static bool RegionConnected(
            int[,] regions, int size, int regionId, int excludeR, int excludeC,
            bool[] inRegionScratch, bool[] visitedScratch, int[] stackScratch)
        {
            Array.Clear(inRegionScratch, 0, inRegionScratch.Length);
            Array.Clear(visitedScratch, 0, visitedScratch.Length);

            int cellCount = 0;
            int seedIndex = -1;
            for (int r = 0; r < size; r++)
            {
                for (int c = 0; c < size; c++)
                {
                    if (regions[r, c] != regionId || (r == excludeR && c == excludeC))
                        continue;

                    int idx = r * size + c;
                    inRegionScratch[idx] = true;
                    cellCount++;
                    if (seedIndex == -1)
                        seedIndex = idx;
                }
            }

            if (seedIndex == -1)
                return false;

            int stackTop = 0;
            stackScratch[stackTop++] = seedIndex;
            visitedScratch[seedIndex] = true;
            int visitedCount = 1;

            while (stackTop > 0)
            {
                int idx = stackScratch[--stackTop];
                int r = idx / size;
                int c = idx % size;

                if (r + 1 < size) visitedCount += TryVisit(r + 1, c);
                if (r - 1 >= 0) visitedCount += TryVisit(r - 1, c);
                if (c + 1 < size) visitedCount += TryVisit(r, c + 1);
                if (c - 1 >= 0) visitedCount += TryVisit(r, c - 1);
            }

            return visitedCount == cellCount;

            int TryVisit(int nr, int nc)
            {
                int nIdx = nr * size + nc;
                if (!inRegionScratch[nIdx] || visitedScratch[nIdx])
                    return 0;

                visitedScratch[nIdx] = true;
                stackScratch[stackTop++] = nIdx;
                return 1;
            }
        }

        private static int CountSolutions(int[,] regions, int size, int cap)
        {
            var colUsed = new bool[size];
            var regionUsed = new bool[size];
            int solutions = 0;

            void Backtrack(int row, int prevCol)
            {
                if (solutions >= cap)
                    return;
                if (row == size)
                {
                    solutions++;
                    return;
                }

                for (int col = 0; col < size; col++)
                {
                    if (colUsed[col])
                        continue;
                    int region = regions[row, col];
                    if (regionUsed[region])
                        continue;
                    if (prevCol >= 0 && Math.Abs(col - prevCol) <= 1)
                        continue;

                    colUsed[col] = true;
                    regionUsed[region] = true;
                    Backtrack(row + 1, col);
                    colUsed[col] = false;
                    regionUsed[region] = false;

                    if (solutions >= cap)
                        return;
                }
            }

            Backtrack(0, -1);
            return solutions;
        }

        private static int[] RegionSizes(int[,] regions, int size)
        {
            var sizes = new int[size];
            for (int r = 0; r < size; r++)
                for (int c = 0; c < size; c++)
                    sizes[regions[r, c]]++;
            return sizes;
        }

        private static double BalanceScore(int[] sizes, int size)
        {
            double average = (double)(size * size) / size;
            double total = 0;
            foreach (int s in sizes)
                total += (s - average) * (s - average);
            return total;
        }

        private static bool HillClimbToUnique(
            int[,] regions, int[] solution, int size, Random rng, int minRegionSize, int maxRegionSize)
        {
            var seedCells = new HashSet<(int, int)>();
            for (int row = 0; row < size; row++)
                seedCells.Add((row, solution[row]));

            int currentCount = CountSolutions(regions, size, SolutionCountCap);
            int[] sizes = RegionSizes(regions, size);
            double currentBalance = BalanceScore(sizes, size);

            var neighborBuffer = new (int, int)[4];
            var inRegionScratch = new bool[size * size];
            var visitedScratch = new bool[size * size];
            var stackScratch = new int[size * size];

            for (int iter = 0; iter < MaxHillClimbIterations; iter++)
            {
                if (currentCount == 1)
                    return true;

                int r = rng.Next(size);
                int c = rng.Next(size);
                if (seedCells.Contains((r, c)))
                    continue;

                int myRegion = regions[r, c];
                int neighborCount = GetNeighbors(r, c, size, neighborBuffer);

                // Reservoir-sample one neighbor whose region differs from myRegion,
                // without allocating a candidates list.
                int chosenIndex = -1;
                int seen = 0;
                for (int i = 0; i < neighborCount; i++)
                {
                    (int nr, int nc) = neighborBuffer[i];
                    if (regions[nr, nc] == myRegion)
                        continue;

                    seen++;
                    if (rng.Next(seen) == 0)
                        chosenIndex = i;
                }

                if (seen == 0)
                    continue;

                (int tr, int tc) = neighborBuffer[chosenIndex];
                int targetRegion = regions[tr, tc];

                if (sizes[myRegion] - 1 < minRegionSize)
                    continue;
                if (sizes[targetRegion] + 1 > maxRegionSize)
                    continue;

                if (!RegionConnected(regions, size, myRegion, r, c, inRegionScratch, visitedScratch, stackScratch))
                    continue;

                regions[r, c] = targetRegion;
                int newCount = CountSolutions(regions, size, SolutionCountCap);
                sizes[myRegion]--;
                sizes[targetRegion]++;
                double newBalance = BalanceScore(sizes, size);

                bool accept = newCount < currentCount || (newCount == currentCount && newBalance < currentBalance);
                if (accept)
                {
                    currentCount = newCount;
                    currentBalance = newBalance;
                }
                else
                {
                    regions[r, c] = myRegion;
                    sizes[myRegion]++;
                    sizes[targetRegion]--;
                }
            }

            return currentCount == 1;
        }
    }
}
