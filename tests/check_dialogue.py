#!/usr/bin/env python3
"""Dialogue-box scanner for Kanto Contests.

Adapted from Johto-Quest-Pack/tests/check_dialogue.py, with the marker set
corrected. That version converts only `\\n` and leaves `\\f` in the string as
ordinary text, so every page-broken line reads as one long over-width row --
on this mod's main.lua it reported 30 findings, nearly all of them false. The
markers the engine actually defines (engine/src/render/TextBox.lua:4-5) are:

    \\n   start the second line of THIS page
    \\v   scroll one line up, waiting for A/B first  (home/text.asm ContText)
    \\f   page break: wait for A, clear the box

So the real rule is per PAGE, not per string literal:

  * split the literal on \\f  -> pages
  * split each page on \\n and \\v -> rows
  * a page may show TWO rows. A third row reached by \\n scrolls with NO
    button wait and the reader loses it -- that is the bug. A row reached by
    \\v is fine at any depth, because ContText waits.
  * every row must fit 18 columns; the font advances a flat 8px inside a
    144px interior, so an over-width row soft-wraps into an extra row and
    hits the same no-wait scroll.

Format specifiers are expanded to a worst case before measuring, because the
overflow that actually shipped was a 10-character nickname landing in a %s.

Usage:  python tests/check_dialogue.py main.lua
Exit 1 if anything is flagged.
"""

from pathlib import Path
import re
import sys

COLUMNS = 18
ROWS_PER_PAGE = 2

# Worst case a specifier can render as. Nicknames cap at 10 glyphs
# (BattleState.lua:4437) and money/score fields are at most 5 digits here.
WORST = [("%s", "A" * 10), ("%d", "99999")]


def strip_comments(source: str) -> str:
    """Drop -- line comments so prose apostrophes cannot desync the scan."""
    out, i, n = [], 0, len(source)
    in_str, quote = False, ""
    while i < n:
        ch = source[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(source[i + 1])
                i += 2
                continue
            if ch == quote:
                in_str = False
            i += 1
            continue
        if ch in "\"'":
            in_str, quote = True, ch
            out.append(ch)
            i += 1
            continue
        if ch == "-" and source.startswith("--", i):
            end = source.find("\n", i)
            if end == -1:
                break
            out.append("\n")
            i = end + 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"' r"|'((?:[^'\\\n]|\\.)*)'")


def unescape(raw: str) -> str:
    return (raw.replace(r"\n", "\n")
               .replace(r"\v", "\v")
               .replace(r"\f", "\f")
               .replace(r"\"", '"')
               .replace(r"\'", "'")
               .replace("\\\\", "\\"))


def widest(row: str) -> int:
    for spec, worst in WORST:
        row = row.replace(spec, worst)
    return len(row)


def suppressed_lines(original: str) -> set:
    """Lines carrying `-- dialogue-ok:` (that line or the one above it).

    The width pass assumes the worst case a specifier can render as, so a
    `%s` that only ever holds a contest CATEGORY (six glyphs at most) reads
    as ten and trips the check. Rather than reword a line that is provably
    fine, mark it and say why -- the reason is the point, so a real overflow
    can never be waved through with a bare marker.
    """
    marked = set()
    for index, line in enumerate(original.splitlines(), start=1):
        match = re.search(r"--\s*dialogue-ok:\s*\S", line)
        if match:
            marked.add(index)
            marked.add(index + 1)
    return marked


def scan(path: Path):
    original = path.read_text(encoding="utf-8")
    skip = suppressed_lines(original)
    source = strip_comments(original)
    findings = []
    for match in LITERAL.finditer(source):
        raw = match.group(1) if match.group(1) is not None else match.group(2)
        if raw is None:
            continue
        text = unescape(raw)
        if not any(m in text for m in "\n\v\f"):
            continue  # not a dialogue page; a bare id or label
        line_no = source.count("\n", 0, match.start()) + 1
        if line_no in skip:
            continue
        short = raw if len(raw) <= 60 else raw[:57] + "..."
        for page in text.split("\f"):
            if page == "":
                continue
            # rows, remembering which separator introduced each one
            rows, waits, cur, waiting = [], [], [], False
            for ch in page:
                if ch in "\n\v":
                    rows.append("".join(cur))
                    waits.append(waiting)
                    cur, waiting = [], (ch == "\v")
                else:
                    cur.append(ch)
            rows.append("".join(cur))
            waits.append(waiting)

            # rows past the second are only safe if \v brought them in
            for index in range(ROWS_PER_PAGE, len(rows)):
                if not waits[index]:
                    findings.append((line_no,
                                     "row %d of %d scrolls with no wait"
                                     % (index + 1, len(rows)), short))
                    break
            for row in rows:
                width = widest(row)
                if width > COLUMNS:
                    findings.append((line_no,
                                     "%d columns, max %d: %r"
                                     % (width, COLUMNS, row), short))
    return findings


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: check_dialogue.py <file.lua>...", file=sys.stderr)
        return 2
    total = 0
    for arg in sys.argv[1:]:
        path = Path(arg)
        for line_no, problem, short in scan(path):
            total += 1
            print("%s:%d: %s  <- %s" % (path.name, line_no, problem, short))
    if total:
        print("\n%d dialogue problem(s)" % total)
        return 1
    print("dialogue OK: every page fits 2 rows x %d columns" % COLUMNS)
    return 0


if __name__ == "__main__":
    sys.exit(main())
