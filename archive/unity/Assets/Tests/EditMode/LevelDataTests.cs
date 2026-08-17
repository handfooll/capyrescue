using System;
using NUnit.Framework;
using Meowdoku.Core;

namespace Meowdoku.Tests
{
    public class LevelDataTests
    {
        [Test]
        public void GetDailySeed_SameDateAndSize_IsDeterministic()
        {
            var date = new DateTime(2026, 8, 17);

            int first = LevelData.GetDailySeed(date, 6);
            int second = LevelData.GetDailySeed(date, 6);

            Assert.AreEqual(first, second);
        }

        [Test]
        public void GetDailySeed_DifferentDates_ProduceDifferentSeeds()
        {
            int today = LevelData.GetDailySeed(new DateTime(2026, 8, 17), 6);
            int tomorrow = LevelData.GetDailySeed(new DateTime(2026, 8, 18), 6);

            Assert.AreNotEqual(today, tomorrow);
        }

        [Test]
        public void GetDailySeed_DifferentSizes_ProduceDifferentSeeds()
        {
            var date = new DateTime(2026, 8, 17);

            int size6 = LevelData.GetDailySeed(date, 6);
            int size8 = LevelData.GetDailySeed(date, 8);

            Assert.AreNotEqual(size6, size8);
        }

        [Test]
        public void GetDailyRegions_MatchesRequestedSize()
        {
            int[,] regions = LevelData.GetDailyRegions(new DateTime(2026, 8, 17), 6);

            Assert.AreEqual(6, regions.GetLength(0));
            Assert.AreEqual(6, regions.GetLength(1));
        }

        [Test]
        public void GetDailyRegions_SameDate_IsStableAcrossCalls()
        {
            var date = new DateTime(2026, 8, 17);

            int[,] first = LevelData.GetDailyRegions(date, 6);
            int[,] second = LevelData.GetDailyRegions(date, 6);

            for (int r = 0; r < 6; r++)
                for (int c = 0; c < 6; c++)
                    Assert.AreEqual(first[r, c], second[r, c]);
        }
    }
}
