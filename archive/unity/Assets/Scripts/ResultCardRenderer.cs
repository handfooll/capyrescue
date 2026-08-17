using UnityEngine;
using UnityEngine.UI;

namespace Meowdoku.Visuals
{
    public class ResultCardRenderer : MonoBehaviour
    {
        private const float CameraPadding = 0.5f;
        private const float CaptionReservedHeight = 1.5f;

        [SerializeField] private Camera shareCamera;
        [SerializeField] private Text solveTimeLabel;
        [SerializeField] private BoardController boardController;
        [SerializeField] private int cardWidth = 1080;
        [SerializeField] private int cardHeight = 1920;

        private RenderTexture _renderTexture;

        private void Awake()
        {
            _renderTexture = new RenderTexture(cardWidth, cardHeight, 16);
            shareCamera.targetTexture = _renderTexture;

            // Portrait render targets (cardWidth < cardHeight) have a horizontal half-width
            // narrower than orthographicSize, so sizing purely off board height would crop
            // the board's sides. Fit whichever dimension actually requires more size.
            Vector2 boardSize = boardController.GetBoardWorldSize();
            float cameraAspect = cardWidth / (float)cardHeight;
            float halfHeightForWidth = (boardSize.x / 2f + CameraPadding) / cameraAspect;
            float halfHeightForHeight = boardSize.y / 2f + CameraPadding + CaptionReservedHeight;
            shareCamera.orthographicSize = Mathf.Max(halfHeightForWidth, halfHeightForHeight);
        }

        public Texture2D CaptureCard(string solveTimeText)
        {
            solveTimeLabel.text = solveTimeText;
            Canvas.ForceUpdateCanvases();

            shareCamera.Render();

            RenderTexture previousActive = RenderTexture.active;
            RenderTexture.active = _renderTexture;

            var texture = new Texture2D(cardWidth, cardHeight, TextureFormat.RGBA32, false);
            texture.ReadPixels(new Rect(0, 0, cardWidth, cardHeight), 0, 0);
            texture.Apply();

            RenderTexture.active = previousActive;

            return texture;
        }
    }
}
