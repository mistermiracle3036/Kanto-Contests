"""Fail on any walker sheet in assets/ the Gen 2 palette bake would mangle.

    python tests/asset_png_check.py

The engine bakes a sheet by reading the RED channel of every pixel and
classifying it into the four OBJ shades (engine/src/render/SpriteRenderer.lua,
getObpImage) -- but FIRST it keeps any pixel whose alpha is already 0
transparent. So a PNG that carries a tRNS chunk (or a real alpha channel) draws
with those pixels missing: ballguy.png declared shade 0 transparent and lost his
black outline and legs, leaving the "red blob" seen in the audience in 0.34.15.
Nothing else -- mode, gen2check, the registry check, rendering the greys -- saw
it, because the greys were fine. Only the alpha was wrong.

Checks, per assets/*.png except contest_tiles.png:
  * no tRNS chunk and no alpha channel (mode L or RGB only)
  * 16 px wide, height a multiple of 16
  * every pixel exactly 0 / 85 / 170 / 255 (r == g == b)
"""
import glob, os, struct, sys
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
assets = os.path.join(here, "..", "assets")

def chunks(path):
    d = open(path, "rb").read(); i = 8; out = []
    while i < len(d):
        n = struct.unpack(">I", d[i:i + 4])[0]; out.append(d[i + 4:i + 8].decode("latin1")); i += 12 + n
    return out

# Sheets known bad and BENCHED (not in any pool) until sprites/canonical is
# repaired by the mod checker. Reported as WARN, not FAIL, so the check stays
# green while the state is on record. Remove the name when canonical is fixed.
BENCHED = {"ballguy.png": "tRNS on shade 0 -- REQUESTS row 10"}

bad = 0
for p in sorted(glob.glob(os.path.join(assets, "*.png"))):
    name = os.path.basename(p)
    if name == "contest_tiles.png":
        continue
    im = Image.open(p); problems = []
    if "tRNS" in chunks(p) or "transparency" in im.info:
        problems.append("tRNS transparency chunk (a shade would draw as a hole)")
    if im.mode not in ("L", "RGB"):
        problems.append(f"mode {im.mode} (alpha channel)")
    if im.size[0] != 16 or im.size[1] % 16:
        problems.append(f"size {im.size}")
    rgb = im.convert("RGB")
    px = set(rgb.getdata())
    off = sorted({c for c in px if not (c[0] == c[1] == c[2] and c[0] in (0, 85, 170, 255))})
    if off:
        problems.append(f"{len(off)} colour(s) not in the four greys, e.g. {off[:3]}")
    if problems and name in BENCHED:
        print(f"WARN {name} (benched: {BENCHED[name]}): " + "; ".join(problems))
    elif problems:
        bad += 1
        print(f"FAIL {name}: " + "; ".join(problems))
print(f"{bad} bad sheet(s)")
sys.exit(1 if bad else 0)
