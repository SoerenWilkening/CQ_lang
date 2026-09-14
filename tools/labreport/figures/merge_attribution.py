#!/usr/bin/env python3
"""Recompute a merge gate's per-track attribution of corpus movers from the
gate's OWN committed evidence file -- never from the prose that quotes it.

A merge-and-gate agent that lands N tracks in one group runs every verdict
mover of the combined corpus sweep on the ORACLE, on each single-track binary
and on the merged binary, one row per mover:

    rel | ORACLE | U | F | P | W | D | MERGED        (merge_gate_probes/attrib_one.sh)

with a verdict of `A:<md5 of the lowered IR>` on exit 0 and `D:<diagnostic>`
otherwise. This script reads that file and re-derives the attribution table:

  * a mover whose MERGED verdict is reproduced by EXACTLY ONE single-track
    binary is attributed to that track;
  * one reproduced by NO single-track binary is a COMPOSITION -- the class the
    group gate exists to find, and the one no per-track gate can see;
  * one reproduced by MORE THAN ONE is AMBIGUOUS and is reported separately
    rather than being silently folded into a track.

Writes a pgfplots-readable table:

    idx  track  movers

Usage:

    tools/labreport/figures/merge_attribution.py \
        docs/labreport/figures/NNN/merge_attribution.dat \
        docs/prd/.../merge_gate_probes/corpus_attribution_<hash>.txt [U,F,P,W,D]

The track column order is the one attrib_one.sh printed; pass it explicitly if
a later gate uses a different set. Lab-report figures are sealed with their
session (docs/labreport/README.md), so each session regenerates into its own
figures/NNN/ dir.
"""
import sys
from collections import Counter


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print(__doc__, file=sys.stderr)
        return 2
    out, src = sys.argv[1], sys.argv[2]
    tracks = (sys.argv[3] if len(sys.argv) == 4 else "U,F,P,W,D").split(",")
    counts: Counter[str] = Counter()
    rows = 0
    for line in open(src):
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("|")
        if len(parts) != len(tracks) + 3:
            print(f"malformed row ({len(parts)} fields): {line[:70]}", file=sys.stderr)
            return 1
        rows += 1
        oracle, merged = parts[1], parts[-1]
        hits = [t for t, v in zip(tracks, parts[2:-1]) if v == merged and v != oracle]
        if len(hits) == 1:
            counts[hits[0]] += 1
        elif not hits:
            counts["COMPOSITION"] += 1
        else:
            counts["AMBIGUOUS"] += 1
    order = sorted(tracks, key=lambda t: -counts[t]) + ["COMPOSITION", "AMBIGUOUS"]
    with open(out, "w") as f:
        f.write("idx track movers\n")
        for i, t in enumerate(order):
            f.write(f"{i} {t} {counts[t]}\n")
    for i, t in enumerate(order):
        print(f"{i} {t} {counts[t]}")
    print(f"{rows} movers -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
