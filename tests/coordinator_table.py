"""Regenerate briefs/CONTEST_COORDINATORS.md from Kanto-Contests/main.lua.

    python Kanto-Contests/tests/coordinator_table.py     (from anywhere)

Reads CAST_GYM / CAST_FOLK / CAST_CUSTOM_RIVAL / CAST_CUSTOM_CROWD, the
Larry roll, KC_PARTNER_POOLS and KC_PARTNERS straight from the source, so
the worksheet is the code rather than a memory of it. The two right-hand
columns are the developer's to fill in (contest-type limits, signature
POKeMON); regenerating rewrites the left four and blanks those two, so copy
any answers out first.
"""
import io, os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MAIN = os.path.join(ROOT, "Kanto-Contests", "main.lua")
OUT = os.path.join(ROOT, "briefs", "CONTEST_COORDINATORS.md")

src = io.open(MAIN, encoding="utf-8").read()


def lua_list(name):
    m = re.search(r"local %s = \{(.*?)\n  \}" % re.escape(name), src, re.S)
    body = re.sub(r"--[^\n]*", "", m.group(1))
    return re.findall(r'"([A-Z0-9_]+)"', body)


def pools():
    m = re.search(r"local KC_PARTNER_POOLS = \{(.*?)\n  \}", src, re.S)
    body = re.sub(r"--[^\n]*", "", m.group(1))
    out = {}
    for key, lst in re.findall(r"(SPRITE_[A-Z0-9_]+)\s*=\s*\{([^}]*)\}", body):
        out[key] = re.findall(r'"([A-Z0-9_]+)"', lst)
    return out


gym, folk, rival = lua_list("CAST_GYM"), lua_list("CAST_FOLK"), lua_list("CAST_CUSTOM_RIVAL")
crowd = lua_list("CAST_CUSTOM_CROWD")
fallback = lua_list("KC_PARTNERS")
P = pools()
odds_m = re.search(r"local LARRY_ODDS = (\d+)", src)
larry_odds = int(odds_m.group(1)) if odds_m else 8


def pretty(sprite):
    return re.sub(r"^SPRITE_(KC_)?", "", sprite).replace("_", " ")


def row(sprite, group, odds):
    pool = P.get(sprite)
    mons = ", ".join(pool) if pool else "*(no pool -- draws from the general list)*"
    return f"| {pretty(sprite)} | {group} | {odds} | {mons} |  |  |"


lines = [
    "# Contest coordinators and what they bring\n",
    "Generated from `Kanto-Contests/main.lua` by `Kanto-Contests/tests/coordinator_table.py`; "
    "regenerate rather than edit the left four columns.\n",
    "**How the three rivals are drawn each contest** (`drawCoordinators`): first a roll for how many "
    "FAMOUS FACES the three include, by the highest rank the player has ever entered -- "
    f"**NORMAL: one face 65%, two 20%, three 5%, none 10%** (more at SUPER/HYPER/MASTER); each face is a custom rival 7 in 10 or a leader/E4 member 3 in 10, at most ONE leader per contest; the rest are trainer classes or named Johto faces**. Separately, **Larry appears in "
    f"1 contest of {larry_odds}**. Their POKeMON is drawn from the pool, seeded per contest, so "
    "the same coordinator can bring a different one next visit.\n",
    "**The two blank columns are yours.** *Contest types* -- leave blank for any; or list "
    "COOL / BEAUTY / CUTE / SMART / TOUGH to restrict which contests this coordinator can "
    "turn up in. *Signature* -- write the one or two POKeMON they should ALWAYS bring, or "
    "leave blank to keep the pool.\n",
    "| Coordinator | Drawn from | Odds | POKeMON pool (today) | Contest types | Signature |",
    "|---|---|---|---|---|---|",
    f"| **LARRY** | own roll | 1 in {larry_odds} contests | "
    + ", ".join(P.get("SPRITE_KC_LARRY", [])) + " |  |  |",
]
for s in rival:
    lines.append(row("SPRITE_" + s, "custom rival", "famous-face slot, 7 in 10"))
for s in gym:
    lines.append(row("SPRITE_" + s, "gym / Elite Four", "famous-face slot, 3 in 10, max one"))
for s in folk:
    lines.append(row("SPRITE_" + s, "trainer class / Johto face", "the remaining slots"))

missing = [s for s in rival + gym + folk if ("SPRITE_" + s) not in P]
lines.append("\n**General list** (used only by a coordinator with no pool of their own): "
             + ", ".join(fallback) + "\n")
lines.append(f"**Coverage:** {len(rival) + len(gym) + len(folk) + 1} coordinator-eligible "
             f"characters; {'all have a pool' if not missing else 'WITHOUT a pool: ' + ', '.join(missing)}.\n")
lines.append("**Audience only, never compete:** "
             + ", ".join(pretty("SPRITE_" + s) for s in crowd) + ".\n")

io.open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
print(f"larry + {len(rival)} rivals + {len(gym)} gym + {len(folk)} folk; missing pools: {missing}")
print("wrote", OUT)
