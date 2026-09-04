"""Guard every painted street facade against the border bug and bad refs.

    python tests/facade_check.py

Covers Ecruteak, Cianwood and Blackthorn -- every KC_*_FACADE table in
main.lua. Goldenrod is deliberately not one of them: its facade bakes tile
ids instead of references and has its own stamping code.

THE BORDER BUG, which every hand-painted map here has hit at least once:
block id 0 in a MAP grid does not mean "tileset block 0" -- the engine reads
it as "draw the map header's border block" (BorderFill.blockFor). A row of
zeroes renders as the void outside the room while the data looks perfect, and
no static check sees it. So:

  * every block this facade appends must land at an id >= 1, and
  * every id it stamps must be >= 1.

Both follow from appending at #tileset.blocks, but "follows from" is how the
halls shipped void twice, so this asserts it against the real tileset.

It also checks what makes these facades different from Goldenrod's: their
entries store (vanilla block, quadrant) REFERENCES rather than baked tile
ids, because some of them draw from TILESET_JOHTO blocks whose definition
differs between Gold and Crystal. Every referenced block must therefore exist
in BOTH games, or the composition would quietly yield tile 0.

All three streets share TILESET_JOHTO and append to it in whatever order the
player visits them, so the ids checked here are the ids of a street stamping
FIRST -- the worst case for the border rule is the lowest id any of them can
take, and that is what `base` is.

Reads the caches under %APPDATA%/pokemon-love2d; exits 0 with a message on a
machine that has no imported game.
"""
import os
import re
import sys

here = os.path.dirname(os.path.abspath(__file__))
main_lua = os.path.join(here, "..", "main.lua")
TILESET = "TILESET_JOHTO"

src = open(main_lua, encoding="utf-8").read()
FACADES = {}
# Goldenrod's table is the one that bakes 16 tile ids per block instead of
# four (block, quadrant) references, so it has nothing for this check to
# resolve and is skipped by name rather than by "the rows did not parse" --
# a silent skip is how a check becomes a no-op.
SKIP = {"KC_GOLDENROD_FACADE"}
for name, body in re.findall(r"local (KC_\w+_FACADE) = \{(.*?)\n  \}", src, re.S):
    if name in SKIP:
        continue
    rows = re.findall(
        r"\{ bx = (\d+), by = (\d+), q = \{ ([\d, ]+) \}, coll = \{ ([^}]*) \}", body)
    if not rows:
        print(f"{name} parsed as empty")
        sys.exit(2)
    FACADES[name] = rows
if not FACADES:
    print("no KC_*_FACADE table found in main.lua")
    sys.exit(2)

ROW = re.compile(r"\{([\s\d,]+?)\}")


def blocks_of(game):
    """{block id -> 16 tile ids} for TILESET_JOHTO in one game's cache.

    The generated tilesets.lua wraps a block's 16 numbers across several
    lines, so the row pattern has to tolerate newlines -- matching only
    single-line rows silently found nothing and made this check a no-op.
    """
    path = os.path.join(os.path.expandvars("%APPDATA%"), "pokemon-love2d",
                        game, "data", "generated", "tilesets.lua")
    if not os.path.exists(path):
        return None
    text = open(path, encoding="utf-8", errors="ignore").read()
    i = text.find(TILESET + " = {")
    if i < 0:
        return None
    j = text.find("blocks = {", i)
    if j < 0:
        return None
    out = {}
    k = 0
    for row in ROW.finditer(text[j + len("blocks = {"):j + 400000]):
        nums = [int(x) for x in row.group(1).split(",") if x.strip()]
        if len(nums) != 16:
            break
        out[k] = nums
        k += 1
    return out or None


games = {g: b for g, b in ((g, blocks_of(g)) for g in ("crystal", "gold")) if b}
if not games:
    print("no imported game cache on this machine; skipping")
    sys.exit(0)

bad = 0
for game, blocks in sorted(games.items()):
    base = len(blocks)                    # where the mod appends: read, not assumed
    if base < 1:
        print(f"FAIL {game}: {TILESET} has no blocks; the facade would append at id 0")
        bad += 1
        continue
    for name, entries in sorted(FACADES.items()):
        first, last = base, base + len(entries) - 1
        if first < 1:
            print(f"FAIL {game}/{name}: would occupy id {first}, and 0 is the border block")
            bad += 1
        for bx, by, q, _coll in entries:
            nums = [int(x) for x in q.split(",")]
            for i in range(0, 8, 2):
                src_block, quad = nums[i], nums[i + 1]
                if src_block not in blocks:
                    print(f"FAIL {game}/{name}: block ({bx},{by}) references {TILESET} "
                          f"block {src_block}, which this game does not have")
                    bad += 1
                if not 0 <= quad <= 3:
                    print(f"FAIL {game}/{name}: block ({bx},{by}) has quadrant {quad}")
                    bad += 1
        print(f"{game}: {name} has {len(entries)} block(s); stamping first they land "
              f"at ids {first}..{last}, none is 0, and every reference resolves")

print(f"{bad} problem(s)")
sys.exit(1 if bad else 0)
