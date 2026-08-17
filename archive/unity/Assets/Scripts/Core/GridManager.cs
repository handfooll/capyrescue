using System;

namespace Meowdoku.Core
{
    public enum CellState
    {
        Empty,
        Cat,
        X
    }

    [Serializable]
    public class Cell
    {
        public int Row { get; }
        public int Column { get; }
        public int RegionId { get; set; }
        public CellState State { get; set; }

        public Cell(int row, int column, int regionId = 0, CellState state = CellState.Empty)
        {
            Row = row;
            Column = column;
            RegionId = regionId;
            State = state;
        }
    }

    public class GridManager
    {
        public const int DefaultSize = 6;

        public int Size { get; }

        private readonly Cell[,] _cells;

        public GridManager(int size = DefaultSize)
        {
            if (size <= 0)
                throw new ArgumentOutOfRangeException(nameof(size), "Grid size must be positive.");

            Size = size;
            _cells = new Cell[size, size];

            for (int row = 0; row < size; row++)
            {
                for (int col = 0; col < size; col++)
                {
                    _cells[row, col] = new Cell(row, col);
                }
            }
        }

        public Cell GetCell(int row, int col)
        {
            ValidateCoordinates(row, col);
            return _cells[row, col];
        }

        public void SetCellState(int row, int col, CellState state)
        {
            ValidateCoordinates(row, col);
            _cells[row, col].State = state;
        }

        public void SetRegionId(int row, int col, int regionId)
        {
            ValidateCoordinates(row, col);
            _cells[row, col].RegionId = regionId;
        }

        public void SetRegions(int[,] regionMap)
        {
            if (regionMap.GetLength(0) != Size || regionMap.GetLength(1) != Size)
                throw new ArgumentException($"Region map must be {Size}x{Size}.", nameof(regionMap));

            for (int row = 0; row < Size; row++)
            {
                for (int col = 0; col < Size; col++)
                {
                    _cells[row, col].RegionId = regionMap[row, col];
                }
            }
        }

        public void ClearBoard()
        {
            for (int row = 0; row < Size; row++)
            {
                for (int col = 0; col < Size; col++)
                {
                    _cells[row, col].State = CellState.Empty;
                }
            }
        }

        public bool IsInBounds(int row, int col)
        {
            return row >= 0 && row < Size && col >= 0 && col < Size;
        }

        private void ValidateCoordinates(int row, int col)
        {
            if (!IsInBounds(row, col))
                throw new ArgumentOutOfRangeException($"Coordinates ({row}, {col}) are outside the {Size}x{Size} grid.");
        }
    }
}
