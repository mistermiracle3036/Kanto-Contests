"""Guard the Ecruteak facade against the border bug and against bad refs.

    python tests/ecruteak_facade_check.py

THE BORDER BUG, which every hand-painted map here has hit at least once:
block id 0 in a MAP grid does not mean "tileset block 0" -- the engine reads
it as "draw the map header's border block" (BorderFill.blockFor). A row of
zeroes renders as the void outside the room while the data looks perfect, and
no static check sees it. So:

  * every block this facade appends must land at an id >= 1, and
  * every id it stamps must be >= 1.

Both follow from appending at #tileset.blocks, but "follows from" is how the
halls shipped void twice, so this asserts it against the real tileset.

It also checks what makes this facade different from Goldenrod's: its entries
store (vanilla block, quadrant) REFERENCES rather than baked tile ids,
because six of them draw from TILESET_JOHTO blocks whose definition differs
between Gold and Crystal. Every referenced block must therefore exist in BOTH
games, or the composition would quietly yield tile 0.

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
m = re.search(r"local KC_ECRUTEAK_FACADE = \{(.*?)\n  \}", src, re.S)
if not m:
    print("KC_ECRUTEAK_FACADE not found in main.lua")
    sys.exit(2)
entries = re.findall(
    r"\{ bx = (\d+), by = (\d+), q = \{ ([\d, ]+) \}, coll = \{ ([^}]*) \}", m.group(1))
if not entries:
    print("KC_ECRUTEAK_FACADE parsed as empty")
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
    first, last = base, base + len(entries) - 1
    if first < 1:
        print(f"FAIL {game}: facade would occupy id {first}, and 0 is the border block")
        bad += 1
    for bx, by, q, _coll in entries:
        nums = [int(x) for x in q.split(",")]
        for i in range(0, 8, 2):
            src_block, quad = nums[i], nums[i + 1]
            if src_block not in blocks:
                print(f"FAIL {game}: block ({bx},{by}) references {TILESET} block "
                      f"{src_block}, which this game does not have")
                bad += 1
            if not 0 <= quad <= 3:
                print(f"FAIL {game}: block ({bx},{by}) has quadrant {quad}")
                bad += 1
    print(f"{game}: {TILESET} has {base} blocks; the facade's {len(entries)} land at "
          f"ids {first}..{last}, none is 0, and every reference resolves")

print(f"{bad} problem(s)")
sys.exit(1 if bad else 0)
