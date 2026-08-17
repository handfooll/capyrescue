using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using Meowdoku.Core;

namespace Meowdoku.Visuals
{
    public class BoardController : MonoBehaviour
    {
        [Header("Setup")]
        [SerializeField] private CellView cellPrefab;
        [SerializeField] private int gridSize = GridManager.DefaultSize;
        [SerializeField] private float cellSize = 1f;

        [Header("Region Colors")]
        [SerializeField] private Color[] regionColors = BuildDefaultRegionColors();

        private GridManager _gridManager;
        private BoardValidator _validator;
        private CellView[,] _cellViews;
        private bool _isSolved;

        public event Action<ValidationResult> Solved;
        public event Action CellStateChanged;

        private void Awake()
        {
            _gridManager = new GridManager(gridSize);
            _validator = new BoardValidator(_gridManager);
            _cellViews = new CellView[gridSize, gridSize];
        }

        private void Start()
        {
            StartCoroutine(GenerateDailyPuzzleThenSpawn());
        }

        // PuzzleGenerator's hill-climbing search has no hard time bound - most
        // seeds converge fast, but a slow one would stall the main thread for
        // multiple seconds if run synchronously. It has zero UnityEngine
        // dependency, so it's safe to run on a background thread; this coroutine
        // waits for it without blocking a frame.
        private IEnumerator GenerateDailyPuzzleThenSpawn()
        {
            DateTime today = DateTime.Today;
            int size = gridSize;
            Task<int[,]> generationTask = Task.Run(() => LevelData.GetDailyRegions(today, size));

            while (!generationTask.IsCompleted)
                yield return null;

            if (generationTask.IsFaulted)
            {
                Debug.LogError($"BoardController: daily puzzle generation failed - {generationTask.Exception?.GetBaseException().Message}");
                yield break;
            }

            _gridManager.SetRegions(generationTask.Result);
            SpawnGrid();
            RefreshValidation();
        }

        private void SpawnGrid()
        {
            if (cellPrefab == null)
            {
                Debug.LogError("BoardController: Cell Prefab is not assigned.");
                return;
            }

            float offset = (gridSize - 1) / 2f;

            for (int row = 0; row < gridSize; row++)
            {
                for (int col = 0; col < gridSize; col++)
                {
                    Vector3 position = new Vector3(
                        (col - offset) * cellSize,
                        (offset - row) * cellSize,
                        0f);

                    Cell cell = _gridManager.GetCell(row, col);

                    CellView view = Instantiate(cellPrefab, position, Quaternion.identity, transform);
                    view.Initialize(row, col);
                    view.SetState(cell.State);
                    view.SetRegionColor(GetRegionColor(cell.RegionId));
                    view.Clicked += HandleCellClicked;

                    _cellViews[row, col] = view;
                }
            }
        }

        public static Color[] BuildDefaultRegionColors()
        {
            string[] hexColors = { "#FFB3BA", "#FFDFBA", "#FFFFBA", "#BAFFC9", "#BAE1FF", "#E6B3FF" };
            var colors = new Color[hexColors.Length];

            for (int i = 0; i < hexColors.Length; i++)
            {
                ColorUtility.TryParseHtmlString(hexColors[i], out colors[i]);
            }

            return colors;
        }

        private Color GetRegionColor(int regionId)
        {
            if (regionColors == null || regionColors.Length == 0)
                return Color.white;

            if (regionId < 0 || regionId >= regionColors.Length)
            {
                Debug.LogWarning($"BoardController: No color assigned for Region ID {regionId}.");
                return Color.white;
            }

            return regionColors[regionId];
        }

        private void HandleCellClicked(CellView view)
        {
            if (_isSolved)
                return;

            CellState current = _gridManager.GetCell(view.Row, view.Column).State;
            CellState next = GetNextState(current);

            _gridManager.SetCellState(view.Row, view.Column, next);
            view.SetState(next);
            CellStateChanged?.Invoke();

            RefreshValidation();
        }

        public void ResetBoard()
        {
            _isSolved = false;
            _gridManager.ClearBoard();

            for (int row = 0; row < gridSize; row++)
            {
                for (int col = 0; col < gridSize; col++)
                {
                    _cellViews[row, col].SetState(CellState.Empty);
                }
            }

            RefreshValidation();
        }

        public Vector2 GetBoardWorldSize()
        {
            return new Vector2(gridSize * cellSize, gridSize * cellSize);
        }

        private static CellState GetNextState(CellState current)
        {
            return current switch
            {
                CellState.Empty => CellState.Cat,
                CellState.Cat => CellState.X,
                _ => CellState.Empty
            };
        }

        private void RefreshValidation()
        {
            ValidationResult result = _validator.Validate();
            var conflictCells = new HashSet<Cell>(result.AllConflicts);

            for (int row = 0; row < gridSize; row++)
            {
                for (int col = 0; col < gridSize; col++)
                {
                    Cell cell = _gridManager.GetCell(row, col);
                    _cellViews[row, col].SetHighlight(conflictCells.Contains(cell));
                }
            }

            if (!_isSolved && WinConditionChecker.IsSolved(_gridManager, result))
            {
                _isSolved = true;
                Solved?.Invoke(result);
            }
        }

        private void OnDestroy()
        {
            if (_cellViews == null)
                return;

            foreach (CellView view in _cellViews)
            {
                if (view != null)
                    view.Clicked -= HandleCellClicked;
            }
        }
    }
}
