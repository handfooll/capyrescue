using System;
using UnityEngine;
using UnityEngine.InputSystem;
using Meowdoku.Core;

namespace Meowdoku.Visuals
{
    [RequireComponent(typeof(BoxCollider2D))]
    public class CellView : MonoBehaviour
    {
        [Header("Renderers")]
        [SerializeField] private SpriteRenderer backgroundRenderer;
        [SerializeField] private SpriteRenderer markerRenderer;
        [SerializeField] private SpriteRenderer highlightRenderer;

        [Header("Marker Sprites")]
        [SerializeField] private Sprite catSprite;
        [SerializeField] private Sprite xSprite;

        private Collider2D _collider;

        public int Row { get; private set; }
        public int Column { get; private set; }
        public CellState CurrentState { get; private set; } = CellState.Empty;

        public event Action<CellView> Clicked;

        private void Awake()
        {
            _collider = GetComponent<Collider2D>();
        }

        private void Update()
        {
            if (Mouse.current == null || !Mouse.current.leftButton.wasPressedThisFrame || Camera.main == null)
                return;

            Vector2 worldPoint = Camera.main.ScreenToWorldPoint(Mouse.current.position.ReadValue());
            if (_collider.OverlapPoint(worldPoint))
                Clicked?.Invoke(this);
        }

        public void Initialize(int row, int column)
        {
            Row = row;
            Column = column;
            name = $"Cell_{row}_{column}";
            SetHighlight(false);
        }

        public void SetState(CellState state)
        {
            CurrentState = state;

            if (markerRenderer == null)
                return;

            markerRenderer.sprite = state switch
            {
                CellState.Cat => catSprite,
                CellState.X => xSprite,
                _ => null
            };
            markerRenderer.enabled = state != CellState.Empty;
        }

        public void SetHighlight(bool isConflict)
        {
            if (highlightRenderer != null)
                highlightRenderer.enabled = isConflict;
        }

        public void SetRegionColor(Color color)
        {
            if (backgroundRenderer != null)
                backgroundRenderer.color = color;
        }
    }
}
