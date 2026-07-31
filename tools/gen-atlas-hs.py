#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""One-time (or re-sync) generator: koko-places.json -> hs/Atlas.hs.

After the initial conversion hs/Atlas.hs is the source of truth and
tools/apply-schedule.sh regenerates koko-places.json from it. Re-run
this only to re-import if the JSON was ever hand-edited (the checker's
drift check flags that anyway).
"""
import io
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
FIELDS = [  # (json key, record field)
    ("id", "pId"), ("name_en", "pNameEn"), ("name_ja", "pNameJa"),
    ("one_liner", "pOneLiner"), ("one_liner_ja", "pOneLinerJa"),
    ("address", "pAddress"), ("addr_geo", "pAddrGeo"), ("plus_code", "pPlusCode"),
    ("lat", "pLat"), ("lng", "pLng"), ("hubs", "pHubs"), ("tags", "pTags"),
    ("priority", "pPriority"), ("status", "pStatus"), ("phone", "pPhone"),
    ("hours", "pHours"), ("maps_query", "pMapsQuery"), ("aliases", "pAliases"), ("needs", "pNeeds"),
    ("vault", "pVault"), ("kind", "pKind"), ("far", "pFar"),
]


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


def m_str(v):
    return "Nothing" if v is None else "Just " + hs_str(v)


def m_dbl(v):
    if v is None:
        return "Nothing"
    r = repr(float(v))
    return "Just " + ("(" + r + ")" if r.startswith("-") else r)


def str_list(xs):
    assert all(isinstance(x, str) for x in xs)
    return "[" + ", ".join(hs_str(x) for x in xs) + "]"


def pair_list(xs):
    for a, b in xs:
        assert isinstance(a, str) and isinstance(b, str)
    return "[" + ", ".join("(%s, %s)" % (hs_str(a), hs_str(b)) for a, b in xs) + "]"


places = json.load(io.open(os.path.join(ROOT, "koko-places.json"), encoding="utf-8"))
assert isinstance(places, list)

out = []
out.append("-- | The place atlas source of truth (155-ish places: statuses,")
out.append("-- opening hours, names, coordinates). Edit THIS file, then run")
out.append("-- tools/apply-schedule.sh to regenerate koko-places.json (and bump")
out.append("-- the SW cache). Generated initially from the JSON by")
out.append("-- tools/gen-atlas-hs.py; owned by hand from then on.")
out.append("module Atlas (Hours (..), Place (..), places) where")
out.append("")
out.append("data Hours = Hours")
out.append("  { hTimezone :: String")
out.append("  , hWeekly :: Maybe [(String, [(String, String)])] -- day -> open intervals; Nothing = hours unknown")
out.append("  , hClosed :: [String] -- explicit closed dates, YYYY-MM-DD")
out.append("  , hNote :: String")
out.append("  , hApprox :: Bool")
out.append("  , hClosedRanges :: [(String, String)] -- inclusive date ranges, e.g. Obon")
out.append("  }")
out.append("")
out.append("data Place = Place")
out.append("  { pId :: String")
out.append("  , pNameEn :: String")
out.append("  , pNameJa :: Maybe String")
out.append("  , pOneLiner :: String")
out.append("  , pOneLinerJa :: Maybe String")
out.append("  , pAddress :: Maybe String")
out.append("  , pAddrGeo :: Maybe String")
out.append("  , pPlusCode :: Maybe String")
out.append("  , pLat :: Maybe Double")
out.append("  , pLng :: Maybe Double")
out.append("  , pHubs :: [String]")
out.append("  , pTags :: [String]")
out.append("  , pPriority :: String")
out.append("  , pStatus :: String")
out.append("  , pPhone :: Maybe String")
out.append("  , pHours :: Hours")
out.append("  , pMapsQuery :: String")
out.append("  , pAliases :: [String] -- extra strings a day card may use for this place (mention scanning)")
out.append("  , pNeeds :: [String]")
out.append("  , pVault :: Maybe String")
out.append("  , pKind :: String")
out.append("  , pFar :: Bool")
out.append("  }")
out.append("")
out.append("places :: [Place]")
out.append("places =")

sep = "  [ "
for p in places:
    assert set(p.keys()) <= {k for k, _ in FIELDS}, sorted(p.keys())
    h = p["hours"]
    assert set(h.keys()) <= {"timezone", "weekly", "closed", "note", "approx", "closed_ranges"}
    w = h["weekly"]
    if w is not None:
        assert list(w.keys()) == DAYS, p["id"]
        weekly = "Just [" + ", ".join('(%s, %s)' % (hs_str(d), pair_list(w[d])) for d in DAYS) + "]"
    else:
        weekly = "Nothing"
    hours = ("Hours %s %s %s %s %s %s" % (
        hs_str(h["timezone"]), "(" + weekly + ")" if w is not None else weekly,
        str_list(h["closed"]), hs_str(h["note"]),
        "True" if h["approx"] else "False",
        pair_list(h.get("closed_ranges") or []),
    ))
    out.append(sep + "Place")
    out.append("      { pId = " + hs_str(p["id"]))
    out.append("      , pNameEn = " + hs_str(p["name_en"]))
    out.append("      , pNameJa = " + m_str(p["name_ja"]))
    out.append("      , pOneLiner = " + hs_str(p["one_liner"]))
    out.append("      , pOneLinerJa = " + m_str(p["one_liner_ja"]))
    out.append("      , pAddress = " + m_str(p["address"]))
    out.append("      , pAddrGeo = " + m_str(p["addr_geo"]))
    out.append("      , pPlusCode = " + m_str(p["plus_code"]))
    out.append("      , pLat = " + m_dbl(p["lat"]))
    out.append("      , pLng = " + m_dbl(p["lng"]))
    out.append("      , pHubs = " + str_list(p["hubs"]))
    out.append("      , pTags = " + str_list(p["tags"]))
    out.append("      , pPriority = " + hs_str(p["priority"]))
    out.append("      , pStatus = " + hs_str(p["status"]))
    out.append("      , pPhone = " + m_str(p["phone"]))
    out.append("      , pHours = " + hours)
    out.append("      , pMapsQuery = " + hs_str(p["maps_query"]))
    out.append("      , pAliases = " + str_list(p.get("aliases") or []))
    out.append("      , pNeeds = " + str_list(p["needs"]))
    out.append("      , pVault = " + m_str(p["vault"]))
    out.append("      , pKind = " + hs_str(p["kind"]))
    out.append("      , pFar = " + ("True" if p["far"] else "False"))
    out.append("      }")
    sep = "  , "
out.append("  ]")

dest = os.path.join(ROOT, "hs", "Atlas.hs")
io.open(dest, "w", encoding="utf-8").write("\n".join(out) + "\n")
print("wrote %s: %d places" % (dest, len(places)))
