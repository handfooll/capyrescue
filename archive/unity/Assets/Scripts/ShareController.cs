using System.IO;
using UnityEngine;

namespace Meowdoku.Visuals
{
    public class ShareController : MonoBehaviour
    {
        private const string ShareFileName = "meowdoku-share.png";

        public void ShareImage(Texture2D image, string message)
        {
            byte[] png = image.EncodeToPNG();
            string path = Path.Combine(Application.temporaryCachePath, ShareFileName);
            File.WriteAllBytes(path, png);

            new NativeShare()
                .AddFile(path)
                .SetSubject("Meowdoku")
                .SetText(message)
                .Share();
        }
    }
}
