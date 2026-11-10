#!/usr/bin/env python3
"""
Generates assets/logo.ans (grimh3xx pixel-art logo, 24-bit color half blocks)
from tools/logo_grid.png — the same grid used by grimh3xx/usbscope.

    python3 tools/gen_logo.py [--full] tools/logo_grid.png assets/logo.ans

default: only the "grimh3xx" wordmark (8 terminal rows). --full: icon + wordmark.
1 image pixel = 1 block; each pair of pixel rows becomes one terminal row (▀ / ▄).
"""
import sys
from PIL import Image


def is_empty(px):
    return (len(px) == 4 and px[3] < 128) or max(px[:3]) < 45


def main():
    args = sys.argv[1:]
    full = "--full" in args
    args = [a for a in args if a != "--full"]
    if len(args) != 2:
        print(__doc__)
        sys.exit(1)
    src, dst = args
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    grid = [[None if is_empty(im.getpixel((x, y))) else im.getpixel((x, y))[:3] for x in range(w)] for y in range(h)]

    if not full:  # keep only the wordmark: rows after the first blank band
        blank = [all(c is None for c in r) for r in grid]
        start = next(y for y in range(h) if blank[y])
        start = next(y for y in range(start, h) if not blank[y])
        grid = grid[start:]
    # trim empty columns
    used = [x for x in range(w) if any(r[x] for r in grid)]
    grid = [r[min(used):max(used) + 1] for r in grid]
    if len(grid) % 2:
        grid.append([None] * len(grid[0]))

    out = []
    for y in range(0, len(grid), 2):
        line = "  "
        for top, bot in zip(grid[y], grid[y + 1]):
            if top and bot:
                line += "\x1b[38;2;%d;%d;%dm\x1b[48;2;%d;%d;%dm▀\x1b[0m" % (*top, *bot)
            elif top:
                line += "\x1b[38;2;%d;%d;%dm▀\x1b[0m" % top
            elif bot:
                line += "\x1b[38;2;%d;%d;%dm▄\x1b[0m" % bot
            else:
                line += " "
        out.append(line.rstrip())
    with open(dst, "w", encoding="utf-8") as f:
        f.write("\n" + "\n".join(out) + "\n\n")
    print(f"{dst}: {len(grid[0])}x{len(out)} cells")


if __name__ == "__main__":
    main()
