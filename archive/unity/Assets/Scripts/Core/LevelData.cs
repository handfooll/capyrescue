using System;

namespace Meowdoku.Core
{
    public static class LevelData
    {
        // Deterministic so everyone playing on the same calendar date, on a board
        // of the same size, sees the same puzzle, without needing a backend to
        // distribute it. Every distinct (size, date) pair gets its own generated,
        // verified-unique-solution puzzle.
        public static int GetDailySeed(DateTime date, int size)
        {
            int dayNumber = date.Date.Subtract(DateTime.MinValue).Days;
            return dayNumber * 1000 + size;
        }

        public static int[,] GetDailyRegions(DateTime date, int size)
        {
            return PuzzleGenerator.Generate(size, GetDailySeed(date, size));
        }
    }
}
