"""Fail on any walker sheet in assets/ the Gen 2 palette bake would mangle,
or whose colour does not match how it is registered.

    python tests/asset_png_check.py

The engine bakes a GREY sheet by reading the RED channel of every pixel and
classifying it into the four OBJ shades (engine/src/render/SpriteRenderer.lua,
getObpImage) -- but FIRST it keeps any pixel whose alpha is already 0
transparent. So a PNG that carries a tRNS chunk (or a real alpha channel) draws
with those pixels missing: ballguy.png declared shade 0 transparent and lost his
black outline and legs, leaving the "red blob" seen in the audience in 0.34.15.
Nothing else -- mode, gen2check, the registry check, rendering the greys -- saw
it, because the greys were fine. Only the alpha was wrong.

A COLOUR sheet (0.37.5) skips that bake entirely: SpriteRenderer.resolveImage
returns the image as-is when the registration says `trueColor = true` and the
game is in GBC colour mode (PaletteFX.honorsTrueColor). That makes the flag
and the bytes one decision, and each way round is a silent failure on device:
a coloured PNG registered WITHOUT trueColor goes through the bake and comes
out in the stock palette, and a grey PNG registered WITH trueColor draws grey.
So the registration row in main.lua is read here and held against the file.

Checks, per assets/*.png except contest_tiles.png:
  * registered in KC_CUSTOM_SPRITES (an unregistered sheet is dead weight or
    a typo in the row)
  * 16 px wide, height a multiple of 16
  * grey (no trueColor): no tRNS chunk and no alpha channel (mode L or RGB),
    every pixel exactly 0 / 85 / 170 / 255 (r == g == b), and NOT the
    approved colour sheet from sprites/canonical_color
  * trueColor: byte-identical to sprites/canonical_color/<name>.png when the
    store is on this machine (the colour is the developer's decision, taken
    from the store, never made here)
"""
import glob, hashlib, os, re, struct, sys
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
assets = os.path.join(here, "..", "assets")
main = os.path.join(here, "..", "main.lua")
colour_store = os.path.join(here, "..", "..", "sprites", "canonical_color")

def chunks(path):
    d = open(path, "rb").read(); i = 8; out = []
    while i < len(d):
        n = struct.unpack(">I", d[i:i + 4])[0]; out.append(d[i + 4:i + 8].decode("latin1")); i += 12 + n
    return out

def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()

# name -> trueColor flag, from the keyed rows
src = open(main, encoding="utf-8").read()
table = src[src.index("local KC_CUSTOM_SPRITES = {"):src.index("for _, row in ipairs(KC_CUSTOM_SPRITES)")]
registered = {}
for m in re.finditer(r'\{ id = "SPRITE_KC_[A-Z0-9_]+", image = "assets/([a-z0-9_]+)\.png"([^}]*)\}', table):
    registered[m.group(1) + ".png"] = "trueColor = true" in m.group(2)

# Sheets known bad and BENCHED (not in any pool) until sprites/canonical is
# repaired by the mod checker. Reported as WARN, not FAIL, so the check stays
# green while the state is on record. Remove the name when canonical is fixed.
BENCHED = {}   # ballguy.png was here 0.34.16-0.34.20; canonical fixed 2026-09-02

bad = 0
for p in sorted(glob.glob(os.path.join(assets, "*.png"))):
    name = os.path.basename(p)
    if name == "contest_tiles.png":
        continue
    im = Image.open(p); problems = []
    if name not in registered:
        problems.append("not registered in KC_CUSTOM_SPRITES")
    tc = registered.get(name, False)
    if im.size[0] != 16 or im.size[1] % 16:
        problems.append(f"size {im.size}")
    store = os.path.join(colour_store, name)
    in_store = os.path.exists(store)
    if tc:
        if in_store and sha(store) != sha(p):
            problems.append("registered trueColor but is not the approved colour sheet "
                            "(sprites/canonical_color) byte-for-byte")
        elif not in_store and os.path.isdir(colour_store):
            problems.append("registered trueColor but no approved colour sheet exists for it")
    else:
        if in_store and sha(store) == sha(p):
            problems.append("is the approved COLOUR sheet but registered without "
                            "trueColor = true (the bake would throw the colour away)")
        if "tRNS" in chunks(p) or "transparency" in im.info:
            problems.append("tRNS transparency chunk (a shade would draw as a hole)")
        if im.mode not in ("L", "RGB"):
            problems.append(f"mode {im.mode} (alpha channel)")
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
missing = [n for n in registered if not os.path.exists(os.path.join(assets, n))]
for n in missing:
    bad += 1
    print(f"FAIL {n}: registered but no such file in assets/")
n_colour = sum(1 for n, t in registered.items() if t)
print(f"{bad} bad sheet(s); {len(registered)} registered, {n_colour} in colour")
sys.exit(1 if bad else 0)
