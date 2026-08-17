using System;
using System.IO;
using Meowdoku.Visuals;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;

namespace Meowdoku.EditorTools
{
    public static class MeowdokuSetup
    {
        private const string PrefabFolder = "Assets/Prefabs";
        private const string PrefabPath = PrefabFolder + "/Cell.prefab";
        private const string MaterialFolder = "Assets/Materials";
        private const string MaterialPath = MaterialFolder + "/CellSprite.mat";
        private const string SpriteFolder = "Assets/Sprites";
        private const string SquareSpritePath = SpriteFolder + "/CellSquare.asset";
        private const string PawSpritePath = SpriteFolder + "/CatPaw.asset";
        private const string CrossSpritePath = SpriteFolder + "/XMark.asset";
        private const string RoundedPanelSpritePath = SpriteFolder + "/RoundedPanel.asset";
        private const int IconTextureSize = 64;
        private const int RoundedPanelTextureSize = 128;
        private const float RoundedPanelCornerRadius = 34f;

        private static readonly Color PaletteScrim = ParseColor("#1E1416", 0.6f);
        private static readonly Color PaletteCard = ParseColor("#FFF6EC");
        private static readonly Color PaletteTextDark = ParseColor("#4A3B35");
        private static readonly Color PaletteAccentPrimary = ParseColor("#FFB454");
        private static readonly Color PaletteAccentSecondary = ParseColor("#8FD3C7");
        private static readonly Color PalettePill = ParseColor("#FFF6EC", 0.92f);

        private static Color ParseColor(string hex, float alpha = 1f)
        {
            ColorUtility.TryParseHtmlString(hex, out Color color);
            color.a = alpha;
            return color;
        }

        private struct GameHud
        {
            public Text HudTimeText;
            public GameObject WinPanel;
            public Text WinSolveTimeText;
            public Button ShareButton;
            public Button ResetButton;
            public Button PlayAgainButton;
        }

        [MenuItem("Meowdoku/Auto-Setup Game")]
        public static void AutoSetupGame()
        {
            CellView cellPrefab = CreateCellPrefab();
            BoardController boardController = AssignPrefabToBoardController(cellPrefab);

            EnsureEventSystem();
            GameHud hud = CreateGameCanvas();
            ResultCardRenderer resultCardRenderer = CreateShareCardRig(boardController);
            WireGameManager(boardController, hud, resultCardRenderer);

            Debug.Log("Meowdoku: Auto-setup complete. Cell prefab, board, HUD, win screen, and share-card rig are wired up.");
        }

        private const float CellVisualSize = 0.9f;

        private static Sprite GetOrCreateSquareSprite()
        {
            Sprite existing = AssetDatabase.LoadAssetAtPath<Sprite>(SquareSpritePath);
            if (existing != null)
                return existing;

            var texture = new Texture2D(4, 4, TextureFormat.RGBA32, false) { name = "CellSquareTexture" };
            var pixels = new Color32[texture.width * texture.height];
            for (int i = 0; i < pixels.Length; i++)
                pixels[i] = Color.white;
            texture.SetPixels32(pixels);
            texture.Apply();

            // Built in code rather than imported from a file, with SpriteMeshType.FullRect set
            // explicitly. The builtin "UI/Skin/UISprite.psd" resource uses a Tight mesh (meant
            // for its rounded-corner UI look), which logs a tiling warning under SpriteDrawMode.Sliced
            // and has no accessible import settings to fix since it isn't a real project asset.
            return CreateAndPersistIconSprite(texture, SquareSpritePath, "CellSquareSprite");
        }

        private static Sprite GetOrCreatePawSprite()
        {
            Sprite existing = AssetDatabase.LoadAssetAtPath<Sprite>(PawSpritePath);
            if (existing != null)
                return existing;

            var texture = new Texture2D(IconTextureSize, IconTextureSize, TextureFormat.RGBA32, false) { name = "CatPawTexture" };
            var pawColor = new Color32(45, 40, 38, 255);
            var pixels = new Color32[IconTextureSize * IconTextureSize];

            for (int y = 0; y < IconTextureSize; y++)
            {
                for (int x = 0; x < IconTextureSize; x++)
                {
                    bool inPad = IsInsideEllipse(x, y, 32f, 20f, 15f, 12f);
                    bool inToe = IsInsideEllipse(x, y, 17f, 43f, 8f, 8f)
                        || IsInsideEllipse(x, y, 32f, 47f, 8.5f, 8.5f)
                        || IsInsideEllipse(x, y, 47f, 43f, 8f, 8f);

                    pixels[y * IconTextureSize + x] = (inPad || inToe) ? pawColor : new Color32(0, 0, 0, 0);
                }
            }

            texture.SetPixels32(pixels);
            texture.Apply();

            return CreateAndPersistIconSprite(texture, PawSpritePath, "CatPawSprite");
        }

        private static Sprite GetOrCreateCrossSprite()
        {
            Sprite existing = AssetDatabase.LoadAssetAtPath<Sprite>(CrossSpritePath);
            if (existing != null)
                return existing;

            var texture = new Texture2D(IconTextureSize, IconTextureSize, TextureFormat.RGBA32, false) { name = "XMarkTexture" };
            var crossColor = new Color32(110, 110, 110, 230);
            var pixels = new Color32[IconTextureSize * IconTextureSize];
            const float margin = 10f;
            const float thickness = 5f;
            const float sqrt2 = 1.41421356f;

            for (int y = 0; y < IconTextureSize; y++)
            {
                for (int x = 0; x < IconTextureSize; x++)
                {
                    bool withinBounds = x >= margin && x <= IconTextureSize - margin && y >= margin && y <= IconTextureSize - margin;
                    float distDiag1 = Mathf.Abs(x - y) / sqrt2;
                    float distDiag2 = Mathf.Abs(x + y - (IconTextureSize - 1)) / sqrt2;
                    bool onDiagonal = distDiag1 <= thickness || distDiag2 <= thickness;

                    pixels[y * IconTextureSize + x] = (withinBounds && onDiagonal) ? crossColor : new Color32(0, 0, 0, 0);
                }
            }

            texture.SetPixels32(pixels);
            texture.Apply();

            return CreateAndPersistIconSprite(texture, CrossSpritePath, "XMarkSprite");
        }

        private static bool IsInsideEllipse(float x, float y, float cx, float cy, float rx, float ry)
        {
            float dx = (x - cx) / rx;
            float dy = (y - cy) / ry;
            return dx * dx + dy * dy <= 1f;
        }

        // Rounded-rect panel/button background. Only the corner boxes get circular
        // falloff (with a 1px antialiased edge); the straight edges and interior stay
        // fully opaque, so 9-slicing (via the returned sprite's border) keeps the
        // corner radius fixed while the middle stretches to any button/panel size.
        private static Sprite GetOrCreateRoundedPanelSprite()
        {
            Sprite existing = AssetDatabase.LoadAssetAtPath<Sprite>(RoundedPanelSpritePath);
            if (existing != null)
                return existing;

            const int size = RoundedPanelTextureSize;
            const float radius = RoundedPanelCornerRadius;

            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false) { name = "RoundedPanelTexture" };
            var pixels = new Color32[size * size];

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float alpha = RoundedRectCoverage(x, y, size, radius);
                    pixels[y * size + x] = new Color32(255, 255, 255, (byte)Mathf.RoundToInt(alpha * 255f));
                }
            }

            texture.SetPixels32(pixels);
            texture.Apply();

            EnsureFolder(SpriteFolder);

            var sprite = Sprite.Create(
                texture,
                new Rect(0, 0, size, size),
                new Vector2(0.5f, 0.5f),
                size,
                0,
                SpriteMeshType.FullRect,
                new Vector4(radius, radius, radius, radius));
            sprite.name = "RoundedPanelSprite";

            AssetDatabase.CreateAsset(texture, RoundedPanelSpritePath);
            AssetDatabase.AddObjectToAsset(sprite, texture);
            AssetDatabase.SaveAssets();

            return AssetDatabase.LoadAssetAtPath<Sprite>(RoundedPanelSpritePath);
        }

        private static float RoundedRectCoverage(int x, int y, int size, float radius)
        {
            float px = x + 0.5f;
            float py = y + 0.5f;
            float left = radius, right = size - radius, bottom = radius, top = size - radius;

            bool nearLeft = px < left;
            bool nearRight = px > right;
            bool nearBottom = py < bottom;
            bool nearTop = py > top;

            if ((nearLeft || nearRight) && (nearBottom || nearTop))
            {
                float cx = nearLeft ? left : right;
                float cy = nearBottom ? bottom : top;
                float dist = Mathf.Sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
                return Mathf.Clamp01(radius - dist + 0.5f);
            }

            return 1f;
        }

        private static void AddSoftShadow(GameObject target)
        {
            if (target.GetComponent<Shadow>() != null)
                return;

            var shadow = target.AddComponent<Shadow>();
            shadow.effectColor = new Color(0f, 0f, 0f, 0.18f);
            shadow.effectDistance = new Vector2(0f, -4f);
        }

        private static Sprite CreateAndPersistIconSprite(Texture2D texture, string path, string spriteName)
        {
            EnsureFolder(SpriteFolder);

            var sprite = Sprite.Create(
                texture,
                new Rect(0, 0, texture.width, texture.height),
                new Vector2(0.5f, 0.5f),
                texture.width,
                0,
                SpriteMeshType.FullRect);
            sprite.name = spriteName;

            AssetDatabase.CreateAsset(texture, path);
            AssetDatabase.AddObjectToAsset(sprite, texture);
            AssetDatabase.SaveAssets();

            return AssetDatabase.LoadAssetAtPath<Sprite>(path);
        }

        private static Font GetLegacyFont()
        {
            const string fontResourceName = "LegacyRuntime.ttf";
            Font font = Resources.GetBuiltinResource<Font>(fontResourceName);

            if (font == null)
                Debug.LogWarning($"MeowdokuSetup: Builtin font resource '{fontResourceName}' not found; UI text will use Unity's default fallback.");

            return font;
        }

        private const float MarkerVisualSize = 0.55f;

        private static CellView CreateCellPrefab()
        {
            Sprite squareSprite = GetOrCreateSquareSprite();
            Sprite pawSprite = GetOrCreatePawSprite();
            Sprite crossSprite = GetOrCreateCrossSprite();

            // URP 2D auto-assigns Sprite-Lit-Default to new SpriteRenderers, which renders
            // black/invisible without a Light2D in the scene. Force URP's unlit 2D sprite
            // shader so cells are visible with no lighting setup required.
            Material spriteMaterial = GetOrCreateSpriteMaterial();

            var root = new GameObject("Cell");

            // Background: always shows the cell's flat region color, regardless of state.
            var backgroundRenderer = root.AddComponent<SpriteRenderer>();
            backgroundRenderer.sprite = squareSprite;
            backgroundRenderer.sharedMaterial = spriteMaterial;
            backgroundRenderer.drawMode = SpriteDrawMode.Sliced;
            backgroundRenderer.size = new Vector2(CellVisualSize, CellVisualSize);

            var collider = root.AddComponent<BoxCollider2D>();
            collider.size = new Vector2(CellVisualSize, CellVisualSize);

            // Marker: the cat paw / X icon drawn on top of the background, per cell state.
            var marker = new GameObject("Marker");
            marker.transform.SetParent(root.transform, false);
            var markerRenderer = marker.AddComponent<SpriteRenderer>();
            markerRenderer.sharedMaterial = spriteMaterial;
            markerRenderer.drawMode = SpriteDrawMode.Sliced;
            markerRenderer.size = new Vector2(MarkerVisualSize, MarkerVisualSize);
            markerRenderer.sortingOrder = 1;
            markerRenderer.enabled = false;

            // Highlight: a translucent red overlay for conflicts, above the marker so a
            // conflicting cat is still visible underneath the tint instead of being hidden.
            var highlight = new GameObject("Highlight");
            highlight.transform.SetParent(root.transform, false);
            var highlightRenderer = highlight.AddComponent<SpriteRenderer>();
            highlightRenderer.sprite = squareSprite;
            highlightRenderer.sharedMaterial = spriteMaterial;
            highlightRenderer.drawMode = SpriteDrawMode.Sliced;
            highlightRenderer.size = new Vector2(CellVisualSize, CellVisualSize);
            highlightRenderer.color = new Color(1f, 0.15f, 0.15f, 0.55f);
            highlightRenderer.sortingOrder = 2;

            CellView cellView = root.AddComponent<CellView>();

            var serializedCellView = new SerializedObject(cellView);
            serializedCellView.FindProperty("backgroundRenderer").objectReferenceValue = backgroundRenderer;
            serializedCellView.FindProperty("markerRenderer").objectReferenceValue = markerRenderer;
            serializedCellView.FindProperty("highlightRenderer").objectReferenceValue = highlightRenderer;
            serializedCellView.FindProperty("catSprite").objectReferenceValue = pawSprite;
            serializedCellView.FindProperty("xSprite").objectReferenceValue = crossSprite;
            serializedCellView.ApplyModifiedPropertiesWithoutUndo();

            EnsureFolder(PrefabFolder);

            GameObject prefabAsset = PrefabUtility.SaveAsPrefabAsset(root, PrefabPath);
            UnityEngine.Object.DestroyImmediate(root);

            return prefabAsset.GetComponent<CellView>();
        }

        private static Material GetOrCreateSpriteMaterial()
        {
            Material existing = AssetDatabase.LoadAssetAtPath<Material>(MaterialPath);
            if (existing != null)
                return existing;

            EnsureFolder(MaterialFolder);

            var material = new Material(Shader.Find("Universal Render Pipeline/2D/Sprite-Unlit-Default"));
            AssetDatabase.CreateAsset(material, MaterialPath);
            return material;
        }

        private static BoardController AssignPrefabToBoardController(CellView cellPrefab)
        {
            var boardController = UnityEngine.Object.FindAnyObjectByType<BoardController>();
            if (boardController == null)
            {
                var go = new GameObject("BoardController");
                boardController = go.AddComponent<BoardController>();
            }

            var serializedBoard = new SerializedObject(boardController);
            serializedBoard.FindProperty("cellPrefab").objectReferenceValue = cellPrefab;

            // Region Colors is a serialized array, so its C# field initializer only ever
            // ran the first time this component was added - it does not "come back" on
            // its own if the saved scene data drifts (e.g. back to Color.black across a
            // recompile). Force it back to the intended palette on every run.
            Color[] defaultRegionColors = BoardController.BuildDefaultRegionColors();
            SerializedProperty regionColorsProp = serializedBoard.FindProperty("regionColors");
            regionColorsProp.arraySize = defaultRegionColors.Length;
            for (int i = 0; i < defaultRegionColors.Length; i++)
                regionColorsProp.GetArrayElementAtIndex(i).colorValue = defaultRegionColors[i];

            serializedBoard.ApplyModifiedPropertiesWithoutUndo();

            EditorUtility.SetDirty(boardController);
            EditorSceneManager.MarkSceneDirty(boardController.gameObject.scene);

            return boardController;
        }

        private static void EnsureEventSystem()
        {
            GameObject go = GameObject.Find("EventSystem");
            if (go == null)
                go = new GameObject("EventSystem", typeof(EventSystem));

            // Active Input Handling is New Input System only in this project (see the project notes
            // Known Gotchas) - the legacy StandaloneInputModule silently does nothing here.
            if (go.GetComponent<InputSystemUIInputModule>() == null)
                go.AddComponent<InputSystemUIInputModule>();
        }

        private static GameObject FindOrCreateChild(Transform parent, string name, params Type[] components)
        {
            Transform existing = parent.Find(name);
            if (existing != null)
                return existing.gameObject;

            var go = new GameObject(name, components);
            go.transform.SetParent(parent, false);
            return go;
        }

        private static Text CreateText(Transform parent, string name, string content, int fontSize, Color color, TextAnchor alignment)
        {
            GameObject go = FindOrCreateChild(parent, name, typeof(RectTransform), typeof(Text));
            var text = go.GetComponent<Text>();
            text.font = GetLegacyFont();
            text.text = content;
            text.fontSize = fontSize;
            text.color = color;
            text.alignment = alignment;
            text.horizontalOverflow = HorizontalWrapMode.Overflow;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            return text;
        }

        // A previous version of this tool parented these directly under the canvas /
        // WinPanel. They've since moved under SafeAreaRoot / WinCard; find-or-create
        // by name doesn't see them at their new path, so scenes set up with the old
        // layout end up with orphaned duplicates left behind at the old path.
        private static void CleanupLegacyUiObjects(Transform canvasTransform)
        {
            DestroyIfExists(canvasTransform, "HudPanel");
            DestroyIfExists(canvasTransform, "HudResetButton");
            DestroyIfExists(canvasTransform, "WinPanel", "WinTitleText");
            DestroyIfExists(canvasTransform, "WinPanel", "WinSolveTimeText");
            DestroyIfExists(canvasTransform, "WinPanel", "ShareButton");
            DestroyIfExists(canvasTransform, "WinPanel", "PlayAgainButton");
        }

        private static void DestroyIfExists(Transform root, params string[] pathSegments)
        {
            Transform current = root;
            foreach (string segment in pathSegments)
            {
                current = current.Find(segment);
                if (current == null)
                    return;
            }

            UnityEngine.Object.DestroyImmediate(current.gameObject);
        }

        private static GameHud CreateGameCanvas()
        {
            GameObject canvasGO = GameObject.Find("GameCanvas");
            if (canvasGO == null)
            {
                canvasGO = new GameObject("GameCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
                var canvas = canvasGO.GetComponent<Canvas>();
                canvas.renderMode = RenderMode.ScreenSpaceOverlay;

                var scaler = canvasGO.GetComponent<CanvasScaler>();
                scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
                scaler.referenceResolution = new Vector2(1080, 1920);
            }

            Transform canvasTransform = canvasGO.transform;
            CleanupLegacyUiObjects(canvasTransform);
            Sprite roundedPanel = GetOrCreateRoundedPanelSprite();

            // SafeAreaRoot clips itself to Screen.safeArea (notch / camera cutout /
            // home indicator) via the SafeArea component; HUD elements anchor inside
            // it so they never sit under those regions on notch devices.
            GameObject safeAreaRoot = FindOrCreateChild(canvasTransform, "SafeAreaRoot", typeof(RectTransform));
            var safeAreaRect = (RectTransform)safeAreaRoot.transform;
            StretchFull(safeAreaRect);
            if (safeAreaRoot.GetComponent<SafeArea>() == null)
                safeAreaRoot.AddComponent<SafeArea>();

            GameObject hudPanel = FindOrCreateChild(safeAreaRect, "HudPanel", typeof(RectTransform), typeof(Image));
            var hudRect = (RectTransform)hudPanel.transform;
            hudRect.anchorMin = new Vector2(0.5f, 1f);
            hudRect.anchorMax = new Vector2(0.5f, 1f);
            hudRect.pivot = new Vector2(0.5f, 1f);
            hudRect.anchoredPosition = new Vector2(0f, -30f);
            hudRect.sizeDelta = new Vector2(360f, 120f);

            var hudPanelImage = hudPanel.GetComponent<Image>();
            hudPanelImage.sprite = roundedPanel;
            hudPanelImage.type = Image.Type.Sliced;
            hudPanelImage.color = PalettePill;
            AddSoftShadow(hudPanel);

            Text hudTimeText = CreateText(hudRect, "HudTimeText", "0:00.00", 60, PaletteTextDark, TextAnchor.MiddleCenter);
            StretchFull((RectTransform)hudTimeText.transform);

            GameObject hudResetButtonGO = FindOrCreateChild(safeAreaRect, "HudResetButton", typeof(RectTransform), typeof(Image), typeof(Button));
            var hudResetButtonRect = (RectTransform)hudResetButtonGO.transform;
            hudResetButtonRect.anchorMin = new Vector2(1f, 1f);
            hudResetButtonRect.anchorMax = new Vector2(1f, 1f);
            hudResetButtonRect.pivot = new Vector2(1f, 1f);
            hudResetButtonRect.sizeDelta = new Vector2(160f, 90f);
            hudResetButtonRect.anchoredPosition = new Vector2(-30f, -30f);

            var hudResetButtonImage = hudResetButtonGO.GetComponent<Image>();
            hudResetButtonImage.sprite = roundedPanel;
            hudResetButtonImage.type = Image.Type.Sliced;
            hudResetButtonImage.color = PalettePill;
            AddSoftShadow(hudResetButtonGO);

            var hudResetButton = hudResetButtonGO.GetComponent<Button>();
            hudResetButton.targetGraphic = hudResetButtonImage;

            Text hudResetLabel = CreateText(hudResetButtonRect, "Label", "Reset", 30, PaletteTextDark, TextAnchor.MiddleCenter);
            StretchFull(hudResetLabel.rectTransform);

            // WinPanel is the full-screen dim scrim, deliberately outside SafeAreaRoot
            // so it still covers the notch cutout / rounded-corner / home-indicator
            // regions. WinCard (its own SafeArea child) holds the actual content so
            // that content stays clear of those regions.
            GameObject winPanel = FindOrCreateChild(canvasTransform, "WinPanel", typeof(RectTransform), typeof(Image));
            var winRect = (RectTransform)winPanel.transform;
            winRect.anchorMin = Vector2.zero;
            winRect.anchorMax = Vector2.one;
            winRect.offsetMin = Vector2.zero;
            winRect.offsetMax = Vector2.zero;

            var winBackground = winPanel.GetComponent<Image>();
            winBackground.sprite = null;
            winBackground.type = Image.Type.Simple;
            winBackground.color = PaletteScrim;

            GameObject winSafeArea = FindOrCreateChild(winRect, "WinSafeArea", typeof(RectTransform));
            var winSafeAreaRect = (RectTransform)winSafeArea.transform;
            StretchFull(winSafeAreaRect);
            if (winSafeArea.GetComponent<SafeArea>() == null)
                winSafeArea.AddComponent<SafeArea>();

            GameObject winCard = FindOrCreateChild(winSafeAreaRect, "WinCard", typeof(RectTransform), typeof(Image));
            var winCardRect = (RectTransform)winCard.transform;
            SetCenteredSize(winCardRect, 860f, 900f);

            var winCardImage = winCard.GetComponent<Image>();
            winCardImage.sprite = roundedPanel;
            winCardImage.type = Image.Type.Sliced;
            winCardImage.color = PaletteCard;
            AddSoftShadow(winCard);

            Text winTitleText = CreateText(winCardRect, "WinTitleText", "You Win!", 72, PaletteTextDark, TextAnchor.MiddleCenter);
            SetCenteredSize(winTitleText.rectTransform, 700f, 120f);
            winTitleText.rectTransform.anchoredPosition = new Vector2(0f, 260f);

            Text winSolveTimeText = CreateText(winCardRect, "WinSolveTimeText", string.Empty, 56, PaletteTextDark, TextAnchor.MiddleCenter);
            SetCenteredSize(winSolveTimeText.rectTransform, 700f, 100f);
            winSolveTimeText.rectTransform.anchoredPosition = new Vector2(0f, 120f);

            GameObject shareButtonGO = FindOrCreateChild(winCardRect, "ShareButton", typeof(RectTransform), typeof(Image), typeof(Button));
            var shareButtonRect = (RectTransform)shareButtonGO.transform;
            SetCenteredSize(shareButtonRect, 620f, 140f);
            shareButtonRect.anchoredPosition = new Vector2(0f, -60f);

            var shareButtonImage = shareButtonGO.GetComponent<Image>();
            shareButtonImage.sprite = roundedPanel;
            shareButtonImage.type = Image.Type.Sliced;
            shareButtonImage.color = PaletteAccentPrimary;
            AddSoftShadow(shareButtonGO);

            var shareButton = shareButtonGO.GetComponent<Button>();
            shareButton.targetGraphic = shareButtonImage;

            Text shareLabel = CreateText(shareButtonRect, "Label", "Share", 48, PaletteTextDark, TextAnchor.MiddleCenter);
            StretchFull(shareLabel.rectTransform);

            GameObject playAgainButtonGO = FindOrCreateChild(winCardRect, "PlayAgainButton", typeof(RectTransform), typeof(Image), typeof(Button));
            var playAgainButtonRect = (RectTransform)playAgainButtonGO.transform;
            SetCenteredSize(playAgainButtonRect, 620f, 140f);
            playAgainButtonRect.anchoredPosition = new Vector2(0f, -230f);

            var playAgainButtonImage = playAgainButtonGO.GetComponent<Image>();
            playAgainButtonImage.sprite = roundedPanel;
            playAgainButtonImage.type = Image.Type.Sliced;
            playAgainButtonImage.color = PaletteAccentSecondary;
            AddSoftShadow(playAgainButtonGO);

            var playAgainButton = playAgainButtonGO.GetComponent<Button>();
            playAgainButton.targetGraphic = playAgainButtonImage;

            Text playAgainLabel = CreateText(playAgainButtonRect, "Label", "Play Again", 44, PaletteTextDark, TextAnchor.MiddleCenter);
            StretchFull(playAgainLabel.rectTransform);

            // GameManager.Awake() also hides this at Play Mode start; setting it here too
            // keeps the edit-time hierarchy from showing the win screen before any puzzle is solved.
            winPanel.SetActive(false);

            return new GameHud
            {
                HudTimeText = hudTimeText,
                WinPanel = winPanel,
                WinSolveTimeText = winSolveTimeText,
                ShareButton = shareButton,
                ResetButton = hudResetButton,
                PlayAgainButton = playAgainButton,
            };
        }

        private static ResultCardRenderer CreateShareCardRig(BoardController boardController)
        {
            GameObject cameraGO = GameObject.Find("ShareCardCamera");
            if (cameraGO == null)
                cameraGO = new GameObject("ShareCardCamera", typeof(Camera));

            var shareCamera = cameraGO.GetComponent<Camera>();
            shareCamera.orthographic = true;
            shareCamera.clearFlags = CameraClearFlags.SolidColor;
            shareCamera.backgroundColor = new Color(0.98f, 0.95f, 0.9f);
            shareCamera.enabled = false;
            shareCamera.transform.position = new Vector3(0f, 0f, -10f);

            GameObject cardCanvasGO = GameObject.Find("ShareCardCanvas");
            if (cardCanvasGO == null)
                cardCanvasGO = new GameObject("ShareCardCanvas", typeof(Canvas));

            var cardCanvas = cardCanvasGO.GetComponent<Canvas>();
            cardCanvas.renderMode = RenderMode.ScreenSpaceCamera;
            cardCanvas.worldCamera = shareCamera;
            cardCanvas.planeDistance = 1f;

            Text solveTimeLabel = CreateText(cardCanvasGO.transform, "SolveTimeLabel", string.Empty, 64, Color.black, TextAnchor.MiddleCenter);
            var labelRect = solveTimeLabel.rectTransform;
            labelRect.anchorMin = new Vector2(0.5f, 0f);
            labelRect.anchorMax = new Vector2(0.5f, 0f);
            labelRect.pivot = new Vector2(0.5f, 0f);
            labelRect.anchoredPosition = new Vector2(0f, 80f);
            labelRect.sizeDelta = new Vector2(900f, 120f);

            var resultCardRenderer = cameraGO.GetComponent<ResultCardRenderer>();
            if (resultCardRenderer == null)
                resultCardRenderer = cameraGO.AddComponent<ResultCardRenderer>();

            var serialized = new SerializedObject(resultCardRenderer);
            serialized.FindProperty("shareCamera").objectReferenceValue = shareCamera;
            serialized.FindProperty("solveTimeLabel").objectReferenceValue = solveTimeLabel;
            serialized.FindProperty("boardController").objectReferenceValue = boardController;
            serialized.ApplyModifiedPropertiesWithoutUndo();

            return resultCardRenderer;
        }

        private static void WireGameManager(
            BoardController boardController,
            GameHud hud,
            ResultCardRenderer resultCardRenderer)
        {
            GameObject go = GameObject.Find("GameManager");
            if (go == null)
                go = new GameObject("GameManager");

            var gameManager = go.GetComponent<GameManager>();
            if (gameManager == null)
                gameManager = go.AddComponent<GameManager>();

            var shareController = go.GetComponent<ShareController>();
            if (shareController == null)
                shareController = go.AddComponent<ShareController>();

            var serialized = new SerializedObject(gameManager);
            serialized.FindProperty("boardController").objectReferenceValue = boardController;
            serialized.FindProperty("hudTimeText").objectReferenceValue = hud.HudTimeText;
            serialized.FindProperty("winPanel").objectReferenceValue = hud.WinPanel;
            serialized.FindProperty("winSolveTimeText").objectReferenceValue = hud.WinSolveTimeText;
            serialized.FindProperty("shareButton").objectReferenceValue = hud.ShareButton;
            serialized.FindProperty("resetButton").objectReferenceValue = hud.ResetButton;
            serialized.FindProperty("playAgainButton").objectReferenceValue = hud.PlayAgainButton;
            serialized.FindProperty("resultCardRenderer").objectReferenceValue = resultCardRenderer;
            serialized.FindProperty("shareController").objectReferenceValue = shareController;
            serialized.ApplyModifiedPropertiesWithoutUndo();

            EditorUtility.SetDirty(gameManager);
            EditorSceneManager.MarkSceneDirty(go.scene);
        }

        private static void StretchFull(RectTransform rect)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }

        private static void SetCenteredSize(RectTransform rect, float width, float height)
        {
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(width, height);
        }

        private static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path))
                return;

            string parent = Path.GetDirectoryName(path)?.Replace('\\', '/');
            string folderName = Path.GetFileName(path);

            if (!string.IsNullOrEmpty(parent) && !AssetDatabase.IsValidFolder(parent))
                EnsureFolder(parent);

            AssetDatabase.CreateFolder(parent, folderName);
        }
    }
}
