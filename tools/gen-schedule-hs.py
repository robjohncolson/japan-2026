#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""One-time (or re-sync) generator: hs/.build/{days,nights}.json -> hs/Schedule.hs.

After the initial conversion the flow reverses: hs/Schedule.hs is the
source of truth and tools/apply-schedule.sh regenerates the JS blocks in
index.html. Re-run this script only to re-import data if the page was
ever hand-edited (drift the checker will flag anyway).
"""
import io
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def hs_str(s):
    out = []
    for ch in s:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif ord(ch) < 0x20:
            out.append("\\%d" % ord(ch))
        else:
            out.append(ch)
    return '"' + "".join(out) + '"'


days = json.load(io.open(os.path.join(ROOT, "hs/.build/days.json"), encoding="utf-8"))
nights = json.load(io.open(os.path.join(ROOT, "hs/.build/nights.json"), encoding="utf-8"))

FIELD_ORDER = ["cls", "label", "label_ja", "detail", "detail_ja"]

lines = []
lines.append("-- | The itinerary source of truth. Edit THIS file, then run")
lines.append("-- tools/apply-schedule.sh to regenerate the DAYS/NIGHTS blocks in")
lines.append("-- index.html (and bump the SW cache). Generated initially from the")
lines.append("-- page by tools/gen-schedule-hs.py; owned by hand from then on.")
lines.append("module Schedule (Card, days, nights) where")
lines.append("")
lines.append("-- (field, value) pairs in page order: cls, label, label_ja, detail, detail_ja")
lines.append("type Card = [(String, String)]")
lines.append("")
lines.append("days :: [(String, Card)]")
lines.append("days =")
sep = "  [ "
for date, card in days.items():
    fields = [k for k in FIELD_ORDER if k in card] + [k for k in card if k not in FIELD_ORDER]
    lines.append(sep + "( " + hs_str(date))
    lines.append("    , [ " + "\n      , ".join("(%s, %s)" % (hs_str(k), hs_str(card[k])) for k in fields))
    lines.append("      ] )")
    sep = "  , "
lines.append("  ]")
lines.append("")
lines.append("-- (first night, last night, name EN, name JA)")
lines.append("nights :: [(String, String, String, String)]")
lines.append("nights =")
sep = "  [ "
for frm, to, names in nights:
    lines.append(sep + "(%s, %s, %s, %s)" % (hs_str(frm), hs_str(to), hs_str(names["en"]), hs_str(names["ja"])))
    sep = "  , "
lines.append("  ]")

out = os.path.join(ROOT, "hs", "Schedule.hs")
io.open(out, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("wrote %s: %d days, %d lodging rows" % (out, len(days), len(nights)))
