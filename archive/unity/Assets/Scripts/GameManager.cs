using UnityEngine;
using UnityEngine.UI;
using Meowdoku.Core;

namespace Meowdoku.Visuals
{
    public class GameManager : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private BoardController boardController;
        [SerializeField] private Text hudTimeText;
        [SerializeField] private GameObject winPanel;
        [SerializeField] private Text winSolveTimeText;
        [SerializeField] private Button shareButton;
        [SerializeField] private Button resetButton;
        [SerializeField] private Button playAgainButton;
        [SerializeField] private ResultCardRenderer resultCardRenderer;
        [SerializeField] private ShareController shareController;

        private readonly SolveTimer _timer = new SolveTimer();
        private bool _timerStarted;

        private void Awake()
        {
            boardController.CellStateChanged += HandleCellStateChanged;
            boardController.Solved += HandleSolved;
            shareButton.onClick.AddListener(HandleShareClicked);
            resetButton.onClick.AddListener(HandleResetClicked);
            playAgainButton.onClick.AddListener(HandleResetClicked);
            winPanel.SetActive(false);
        }

        private void Update()
        {
            if (_timer.IsRunning)
                hudTimeText.text = FormatElapsed(_timer.Elapsed);
        }

        private void HandleCellStateChanged()
        {
            if (_timerStarted)
                return;

            _timerStarted = true;
            _timer.Start();
        }

        private void HandleSolved(ValidationResult result)
        {
            _timer.Stop();

            string label = FormatElapsed(_timer.Elapsed);
            winSolveTimeText.text = label;
            winPanel.SetActive(true);
        }

        private void HandleResetClicked()
        {
            _timer.Stop();
            _timer.Reset();
            _timerStarted = false;
            hudTimeText.text = FormatElapsed(_timer.Elapsed);
            winPanel.SetActive(false);
            boardController.ResetBoard();
        }

        private void HandleShareClicked()
        {
            string label = FormatElapsed(_timer.Elapsed);
            Texture2D card = resultCardRenderer.CaptureCard(label);
            shareController.ShareImage(card, $"I solved today's Meowdoku in {label}! 🐱");
        }

        private static string FormatElapsed(System.TimeSpan elapsed)
        {
            return $"{(int)elapsed.TotalMinutes}:{elapsed.Seconds:D2}.{elapsed.Milliseconds / 10:D2}";
        }

        private void OnDestroy()
        {
            boardController.CellStateChanged -= HandleCellStateChanged;
            boardController.Solved -= HandleSolved;
        }
    }
}
