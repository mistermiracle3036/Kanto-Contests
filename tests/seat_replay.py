"""Replay Kanto Contests' stage seating for every possible seed and keep the seeds
that reproduce the arrangement in the developer's screenshot.

The draw is a Park-Miller LCG (seededRng) consumed in a fixed order by
drawCoordinators + the seat fill (main.lua ensureStageCast). Reimplemented here
line for line; seed = contestCount*131 + salt, salt in [7, 100009], so every
reachable seed is a small integer.

It mirrors the CURRENT main.lua pools and guards, so it can only explain a
screenshot taken on the current build. Edit observed() to what the screenshot
shows, then run:  python tests/seat_replay.py
(0.34.15's red blob: seed 24618 -> seat (1,8) = SPRITE_KC_BALLGUY.)
"""
import re, sys, os
import numpy as np
from PIL import Image

SRC = open(r"C:\Users\dwitt\gen1recomp-work\Kanto-Contests\main.lua", encoding="utf-8").read()

def lua_list(name):
    m = re.search(r'local %s = \{(.*?)\n  \}' % name, SRC, re.S)
    body = re.sub(r'--[^\n]*', '', m.group(1))
    return re.findall(r'"([A-Z0-9_]+)"', body)

CAST_GYM = lua_list("CAST_GYM"); CAST_FOLK = lua_list("CAST_FOLK")
CAST_CUSTOM_RIVAL = lua_list("CAST_CUSTOM_RIVAL"); CAST_CUSTOM_CROWD = lua_list("CAST_CUSTOM_CROWD")
pairs_body = re.search(r'local CAST_PAIRS = \{(.*?)\n  \}', SRC, re.S).group(1)
CAST_PAIRS = re.findall(r'\{ "([A-Z0-9_]+)", "([A-Z0-9_]+)" \}', pairs_body)
seats_body = re.search(r'local STAGE_SEATS = \{(.*?)\n  \}', SRC, re.S).group(1)
STAGE_SEATS = [(int(x), int(y), f) for x, y, f in re.findall(r'x = (\d+), y = *(\d+), face = (\w+)', seats_body)]
STAND_ONLY = set(re.findall(r'(\w+) = true', re.search(r'local STAND_ONLY = \{([^}]*)\}', SRC).group(1)))
LARRY_ODDS = int(re.search(r'local LARRY_ODDS = (\d+)', SRC).group(1))
CROWD_MIN, CROWD_MAX = map(int, re.search(r'local CROWD_MIN, CROWD_MAX = (\d+), (\d+)', SRC).groups())
CROWD_NAMED_UNTIL = int(re.search(r'local CROWD_NAMED_UNTIL = (\d+)', SRC).group(1))
N_COORD = 3
print(f"pools: gym {len(CAST_GYM)} folk {len(CAST_FOLK)} rival {len(CAST_CUSTOM_RIVAL)} crowd {len(CAST_CUSTOM_CROWD)} pairs {len(CAST_PAIRS)} seats {len(STAGE_SEATS)} larry 1/{LARRY_ODDS} crowd {CROWD_MIN}-{CROWD_MAX} named<= {CROWD_NAMED_UNTIL}")

def seeded(seed):
    s = seed % 2147483647
    if s <= 0: s += 2147483646
    def rnd(n):
        nonlocal s
        s = (s * 16807) % 2147483647
        return (s % n) + 1
    return rnd

def draw_from(pool, used, rnd):
    for _ in range(40):
        pick = pool[rnd(len(pool)) - 1]
        if pick and pick not in used:
            used.add(pick); return pick
    return None

def draw_coordinators(rnd, used):
    out, heavy = [], False
    if rnd(LARRY_ODDS) == 1:
        out.append("SPRITE_KC_LARRY"); used.add("SPRITE_KC_LARRY")
    while len(out) < N_COORD:
        roll = rnd(10)
        if roll <= 5: pool = CAST_CUSTOM_RIVAL
        elif roll <= 7 and not heavy: pool = CAST_GYM
        else: pool = CAST_FOLK
        pick = draw_from(pool, used, rnd) or draw_from(CAST_FOLK, used, rnd)
        if not pick: break
        if pool is CAST_GYM: heavy = True
        out.append("SPRITE_" + pick)
    return out

def adjacent_pairs(chosen):
    out = []
    for a in range(len(chosen)):
        for b in range(a + 1, len(chosen)):
            p, q = chosen[a], chosen[b]
            if abs(p[0] - q[0]) + abs(p[1] - q[1]) == 1:
                out.append((a, b))
    return out

def seating(seed):
    rnd = seeded(seed); used = set()
    coords = draw_coordinators(rnd, used)
    pool = list(STAGE_SEATS)
    for k in range(len(pool), 1, -1):          # for k = #pool, 2, -1
        m = rnd(k)
        pool[k - 1], pool[m - 1] = pool[m - 1], pool[k - 1]
    take = CROWD_MIN + rnd(CROWD_MAX - CROWD_MIN + 1) - 1
    chosen = pool[:min(take, len(pool))]
    seat_for = {}
    if rnd(2) == 1:
        adj = adjacent_pairs(chosen)
        if adj:
            slot = adj[rnd(len(adj)) - 1]
            pair = CAST_PAIRS[rnd(len(CAST_PAIRS)) - 1]
            if pair and pair[0] not in used and pair[1] not in used:
                seat_for[slot[0]] = "SPRITE_" + pair[0]; seat_for[slot[1]] = "SPRITE_" + pair[1]
                used.add(pair[0]); used.add(pair[1])
    out = {}
    for i, seat in enumerate(chosen, start=1):
        sprite = seat_for.get(i - 1)
        if not sprite:
            roll = rnd(10)
            if i > CROWD_NAMED_UNTIL:
                pool_ = CAST_GYM if roll == 1 else CAST_FOLK
            else:
                pool_ = CAST_CUSTOM_CROWD if roll <= 2 else (CAST_CUSTOM_RIVAL if roll == 3 else (CAST_GYM if roll == 4 else CAST_FOLK))
            pick = draw_from(pool_, used, rnd) or draw_from(CAST_FOLK, used, rnd)
            if pick and pick in STAND_ONLY and seat[2] != "FACE_DOWN":   # mirrors main.lua's guard
                pick = draw_from(CAST_FOLK, used, rnd)
            sprite = ("SPRITE_" + pick) if pick else None
        if sprite:
            out[(seat[0], seat[1])] = sprite
    return coords, out

# ---- what the screenshot shows -------------------------------------------
# Cells are read relative to the left seat column (x=1): Granny sits directly
# above the blob, a capped boy above her, and the seat above that is empty.
# Two vertical placements are possible, so both are scored.
def observed(y_left_top):
    """y_left_top = y of the capped boy in the left column (5 or 6)."""
    yb = y_left_top
    obs = {
        "filled": set(), "empty": set(),
        "granny": (1, yb + 1), "blob": (1, yb + 2),
    }
    obs["filled"] |= {(1, yb), (1, yb + 1), (1, yb + 2)}
    for y in range(5, 9):
        if y not in (yb, yb + 1, yb + 2): obs["empty"].add((1, y))
    # back row y=2: x=3..6 filled, 2 and 7 empty.  Row y=4: x=4 and 7 filled.
    obs["filled"] |= {(3, 2), (4, 2), (5, 2), (6, 2), (4, 4), (7, 4)}
    obs["empty"] |= {(2, 2), (7, 2), (2, 4), (3, 4), (5, 4), (6, 4)}
    # front row y=12: x=2,3 and 6,7 filled; x=1 empty (x=8 uncertain)
    obs["filled"] |= {(2, 12), (3, 12), (6, 12), (7, 12)}
    obs["empty"] |= {(1, 12)}
    return obs

def score(seats, obs):
    s = 0
    for c in obs["filled"]:
        s += 1 if c in seats else -1
    for c in obs["empty"]:
        s += 1 if c not in seats else -1
    if seats.get(obs["granny"]) == "SPRITE_GRANNY": s += 4
    return s

best = []
for yb in (5, 6):
    obs = observed(yb)
    perfect = len(obs["filled"]) + len(obs["empty"]) + 4
    for seed in range(1, 131 * 60 + 100010):
        coords, seats = seating(seed)
        sc = score(seats, obs)
        if sc >= perfect - 2:
            best.append((sc, yb, seed, seats.get(obs["blob"]), coords, seats))
best.sort(key=lambda t: -t[0])
print(f"\n{len(best)} seed(s) within 2 of a perfect match")
for sc, yb, seed, blob, coords, seats in best[:12]:
    print(f"score {sc:2d} boy-at-y{yb} seed {seed:6d}  blob seat -> {blob}   coordinators {coords}")
    print("    ", sorted(seats.items(), key=lambda kv: (kv[0][1], kv[0][0])))
