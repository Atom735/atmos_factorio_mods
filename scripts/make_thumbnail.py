#!/usr/bin/env python3
"""Compose a mod thumbnail from artwork and the shared ATMOS frame.

Usage:
    py -3 scripts/make_thumbnail.py <artwork> <mod_folder> [--size 144]
    py -3 scripts/make_thumbnail.py --build-frame <frame_source>

The frame template lives in assets/thumbnail_frame.png (RGBA, transparent window).
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FRAME_PATH = ROOT / "assets" / "thumbnail_frame.png"
DARK_THRESHOLD = 24


def build_frame(source: Path) -> None:
    """Turn the dark window of a frame render into transparency via flood fill from the center."""
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    mask = Image.new("L", image.size, 0)
    gray = image.convert("L")
    seed = (width // 2, height // 2)
    marker = Image.eval(gray, lambda v: 255 if v <= DARK_THRESHOLD else 0)
    ImageDraw.floodfill(marker, seed, 128)
    mask = Image.eval(marker, lambda v: 255 if v == 128 else 0)
    alpha = Image.eval(mask, lambda v: 255 - v)
    image.putalpha(alpha)
    FRAME_PATH.parent.mkdir(parents=True, exist_ok=True)
    image.save(FRAME_PATH)
    box = mask.getbbox()
    print(f"Frame saved -> {FRAME_PATH} window={box}")


def window_box(frame: Image.Image):
    alpha = frame.getchannel("A")
    transparent = Image.eval(alpha, lambda v: 255 if v < 128 else 0)
    return transparent.getbbox()


def cover(image: Image.Image, size):
    target_w, target_h = size
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def compose(artwork: Path, mod_folder: Path, size: int) -> None:
    if not FRAME_PATH.exists():
        sys.exit(f"Missing frame template: {FRAME_PATH} (run with --build-frame first)")
    frame = Image.open(FRAME_PATH).convert("RGBA")
    box = window_box(frame)
    if not box:
        sys.exit("Frame template has no transparent window")
    canvas = Image.new("RGBA", frame.size, (0, 0, 0, 255))
    art = cover(Image.open(artwork).convert("RGBA"), (box[2] - box[0], box[3] - box[1]))
    canvas.paste(art, box[:2])
    canvas.alpha_composite(frame)
    result = canvas.convert("RGB").resize((size, size), Image.LANCZOS)
    out = mod_folder / "thumbnail.png"
    result.save(out)
    print(f"Thumbnail saved -> {out}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("artwork", nargs="?", type=Path)
    parser.add_argument("mod_folder", nargs="?", type=Path)
    parser.add_argument("--size", type=int, default=144)
    parser.add_argument("--build-frame", type=Path, metavar="SOURCE")
    args = parser.parse_args()

    if args.build_frame:
        build_frame(args.build_frame)
        return
    if not (args.artwork and args.mod_folder):
        parser.error("artwork and mod_folder are required")
    compose(args.artwork, args.mod_folder, args.size)


if __name__ == "__main__":
    main()
