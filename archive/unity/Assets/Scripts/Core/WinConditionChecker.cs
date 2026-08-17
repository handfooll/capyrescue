using System.Collections.Generic;

namespace Meowdoku.Core
{
    public static class WinConditionChecker
    {
        public static bool IsSolved(GridManager gridManager, ValidationResult validationResult)
        {
            if (!validationResult.IsValid)
                return false;

            int size = gridManager.Size;
            var catCountByRow = new int[size];
            var catCountByColumn = new int[size];
            var catCountByRegion = new Dictionary<int, int>();
            var allRegionIds = new HashSet<int>();

            for (int row = 0; row < size; row++)
            {
                for (int col = 0; col < size; col++)
                {
                    Cell cell = gridManager.GetCell(row, col);
                    allRegionIds.Add(cell.RegionId);

                    if (cell.State != CellState.Cat)
                        continue;

                    catCountByRow[row]++;
                    catCountByColumn[col]++;
                    catCountByRegion[cell.RegionId] = catCountByRegion.TryGetValue(cell.RegionId, out int count)
                        ? count + 1
                        : 1;
                }
            }

            for (int i = 0; i < size; i++)
            {
                if (catCountByRow[i] != 1 || catCountByColumn[i] != 1)
                    return false;
            }

            foreach (int regionId in allRegionIds)
            {
                if (!catCountByRegion.TryGetValue(regionId, out int count) || count != 1)
                    return false;
            }

            return true;
        }
    }
}
