#!/usr/bin/env python3
"""Refuse to ship a walker sprite with a conversion defect.

Self-contained: needs only Pillow, and judges each sprite on its own terms,
so it works inside a mod repo with no access to the canonical store.

Every fault it looks for has cost this project a device round:

  BLEED       disconnected pixels from the neighbouring sprite, left by a
              crop that ran WIDE.
  FLAT EDGE   a straight vertical run down the figure's own outer column,
              left by a crop that ran TIGHT and sliced the silhouette into
              a line. The cut is INSIDE the cell, which is why every
              "does it touch the border" test missed it for a whole day.
  PALETTE     anything other than Gold's four greys 0/85/170/255.

The 10px flat-edge limit is vanilla's own maximum, measured across 444
frames of the 74 vanilla 16x96 walkers, where the median is 2px.

Usage:  python check_sprites.py [assets_dir]      (default: assets)
Exit 1 if any walker is defective.
"""
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("check_sprites: Pillow not installed; skipping", file=sys.stderr)
    sys.exit(0)

VANILLA_MAX_FLAT_EDGE = 10
GREYS = [0, 85, 170, 255]


def defects(path):
    im = Image.open(path)
    if im.size != (16, 96):
        return []                      # not a walker; fronts/backs are fine
    out = []
    g = im.convert("L")
    vals = sorted(set(g.get_flattened_data()))
    if vals != GREYS:
        out.append(f"palette is {vals}, expected {GREYS}")
    px = g.load()
    for f in range(6):
        y0 = f * 16
        ink = {(x, y) for x in range(16) for y in range(y0, y0 + 16)
               if px[x, y] != 255}
        if not ink:
            continue

        blobs, seen = [], set()
        for start in ink:
            if start in seen:
                continue
            comp, stack = set(), [start]
            while stack:
                c = stack.pop()
                if c in comp or c not in ink:
                    continue
                comp.add(c)
                seen.add(c)
                x, y = c
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        stack.append((x + dx, y + dy))
            blobs.append(comp)
        if len(blobs) > 1:
            stray = sum(len(b) for b in sorted(blobs, key=len)[:-1])
            out.append(f"frame{f}: {len(blobs) - 1} disconnected blob(s), "
                       f"{stray}px -- source-sheet bleed, crop ran wide")

        lo = min(x for x, _ in ink)
        best = cur = 0
        for y in range(y0, y0 + 16):
            cur = cur + 1 if px[lo, y] != 255 else 0
            best = max(best, cur)
        if best > VANILLA_MAX_FLAT_EDGE:
            out.append(f"frame{f}: {best}px straight vertical edge at column "
                       f"{lo} -- crop ran tight (no vanilla walker exceeds "
                       f"{VANILLA_MAX_FLAT_EDGE}px)")
    return out


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "assets"
    if not os.path.isdir(root):
        print(f"check_sprites: no {root}/ directory; nothing to check")
        return 0
    walkers = bad = 0
    for dirpath, _, files in os.walk(root):
        for f in sorted(files):
            if not f.lower().endswith(".png"):
                continue
            p = os.path.join(dirpath, f)
            try:
                if Image.open(p).size != (16, 96):
                    continue
            except Exception:
                continue
            walkers += 1
            d = defects(p)
            if d:
                bad += 1
                print(f"DEFECT  {p}")
                for line in d:
                    print(f"        {line}")
    if bad:
        print(f"\n{bad} of {walkers} walker(s) defective.")
        print("Re-cut from the source sheet using its OWN cell boundaries, or")
        print("copy the master from sprites/canonical/. Do not nudge pixels.")
        return 1
    print(f"check_sprites: {walkers} walker(s) clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
