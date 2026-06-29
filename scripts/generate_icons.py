"""Generate Android launcher icons from assets/images/logo_white.png.

Produces:
  - drawable/ic_launcher_foreground.png  (transparent bg, white mark) - 432x432
  - drawable/ic_launcher_background.png  (solid wine #8A1538)        - 432x432
  - mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png  (bitmap fallback)

Adaptive icon (v26+) uses the drawables above; older Androids fall back
to the mipmap bitmaps.
"""
from PIL import Image
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "mobile", "android", "app", "src", "main", "res")
SRC = os.path.join(ROOT, "mobile", "assets", "images", "logo_white.png")

WINE = (138, 21, 56)            # #8A1538 — Najot Nur brand
WINE_TOLERANCE = 60             # how far from WINE a pixel may be and still be
                                # considered "background" (gets alpha=0)


def wine_distance(rgb):
    return max(abs(rgb[0] - WINE[0]),
               abs(rgb[1] - WINE[1]),
               abs(rgb[2] - WINE[2]))


def make_foreground(src_path, out_path, size=432):
    """Drop the wine background of logo_white.png → transparent foreground."""
    img = Image.open(src_path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if wine_distance((r, g, b)) <= WINE_TOLERANCE:
                pixels[x, y] = (r, g, b, 0)
    img = img.resize((size, size), Image.LANCZOS)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, "PNG")
    print(f"  {os.path.relpath(out_path, ROOT)}  ({size}x{size})")


def make_background(out_path, size=432):
    """Solid wine color background."""
    img = Image.new("RGB", (size, size), WINE)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, "PNG")
    print(f"  {os.path.relpath(out_path, ROOT)}  ({size}x{size})")


def make_mipmaps(src_path):
    """Bitmap ic_launcher.png + ic_launcher_round.png for pre-Android 8."""
    src = Image.open(src_path).convert("RGBA")
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in sizes.items():
        for name in ("ic_launcher.png", "ic_launcher_round.png"):
            out = os.path.join(RES, folder, name)
            os.makedirs(os.path.dirname(out), exist_ok=True)
            src.resize((size, size), Image.LANCZOS).save(out, "PNG")
            print(f"  {os.path.relpath(out, ROOT)}  ({size}x{size})")


def main():
    if not os.path.exists(SRC):
        print(f"Source logo not found: {SRC}", file=sys.stderr)
        sys.exit(1)

    print("Foreground (transparent):")
    make_foreground(
        SRC,
        os.path.join(RES, "drawable", "ic_launcher_foreground.png"),
    )

    print("Background (wine):")
    make_background(
        os.path.join(RES, "drawable", "ic_launcher_background.png"),
    )

    print("Mipmap bitmaps:")
    make_mipmaps(SRC)

    print("\nDone.")


if __name__ == "__main__":
    main()
