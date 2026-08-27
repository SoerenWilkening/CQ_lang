#!/usr/bin/env python3
"""census_03_orphan_rails.py — Inc-0 census 0.3: the ORPHAN-RAIL before-picture
for Inc 5/6 (M-B interior-rail uncompute).

Extends bd test_C_libtooling-iwr7's one-off sweep — which looked only at
`cq_template_icmp_*` and `cq_template_zext_i32_to_i64` — to EVERY rail-minting
producer in every committed golden, and splits the result by producer opcode
family so the Inc-5 target population is a table rather than an anecdote.

================================ WHAT IT MEASURES ==========================
Corpus: every `tests/e2e/*.expected.log`. These are TRACES, not IR: the runtime
prints one line per gate, and a rail handle is printed as `h<N>` from a globally
MONOTONIC counter (`cqrt_alloc_handle` in runtime/cq_runtime.c:64-68 — never
reused, never recycled), so a handle name identifies exactly one rail for the
whole program and a pure textual sweep over the file is EXACT, not approximate.

An ORPHAN is a rail `h<N>` that

  (i)  is DEFINED by a `cq_template_*` or a `cqrt_qram_load_<W>` trace line
       (`… -> h<N>`), and
  (ii) is never mentioned again on any LATER line of that golden.

`cqrt_alloc_*`-minted rails are EXCLUDED, per iwr7's rationale, and the reason is
load-bearing rather than cosmetic: Rule 6 legitimately leaves a not-provably-|0>
rail ALLOCATED, and four committed fixtures declare exactly that leak correct, so
a lone `cqrt_alloc_*` line is not evidence of anything. A rail that a TEMPLATE
computed is different: it was written with `f(operands)` and nothing ever undid
that write, so it is a forward gate on a rail that is never uncomputed and never
freed — Rule 6/8 garbage, invisible to `opt -verify` and (bd
test_C_libtooling-1739 hole 1) invisible to `free_pairing_check.py`, which counts
only `cqrt_alloc_*` mints.

Also counted, in their own columns rather than merged into the headline:
  * `_inv`-minted orphans. A `cq_template_..._inv(...) -> h<N>` mints a rail the
    ABI does not name — the bd 8txa phantom handle. Before 8txa these were the
    single largest family; they are counted separately so the headline number
    never silently absorbs them.
  * `cqrt_tape_write_<W>` results. The output tape is KEPT BY DESIGN (Phase 7.6:
    never freed, never uncomputed — the Bennett output tape), so a tape rail
    mentioned once is CORRECT and is excluded from the orphan count. Counted so
    that exclusion is visible.

=================== THE WIDER POPULATION, REPORTED BESIDE IT ===============
The orphan definition above is iwr7's and it is NARROW: "never mentioned again".
The Inc-5 (M-B interior-rail uncompute) target population is strictly bigger and
is reported in its own block, never merged into the orphan headline:

  UNDISCHARGED — a `cq_template_*` / `cqrt_qram_load_<W>` rail with no `_unc`
  naming it in the OUT slot, no `cqrt_free` of it, and no `cqrt_measure_*` of it,
  EVEN IF it is mentioned again. This is bd test_C_libtooling-6uqc's actual
  defect shape: the condition-provenance chain `sitofp -> fadd -> sqrt` is
  mentioned on every later line that consumes it, so it is INVISIBLE to the
  orphan definition, while being exactly the live basis record the ticket is
  about. Verified by hand on `slice_control_seq_grover.expected.log`, whose two
  undischarged rails are `h1` (the `add`) and `h4` (the `sub`) — bd
  test_C_libtooling-nepx's own example, and neither is an orphan.

============================ APPROXIMATION DIRECTIONS ======================
  A1  A trace is one EXECUTION. A gate inside a classical branch not taken at
      trace time does not appear at all. DIRECTION: UNDER-counts (the census is
      a floor on the orphan population, never a ceiling).
  A2  "Never mentioned again" is textual. Because handles are globally monotonic
      and printed only as `h<N>`, and immediates print as bare decimals with no
      `h`, there is no aliasing between a rail name and a literal. This clause
      is exact.
  A3  A rail defined on the LAST line of a golden is an orphan by construction.
      That is not a false positive — nothing ever undoes it — but it is counted
      separately (`orphans_at_eof`) because it is the shape most likely to be a
      deliberate "kept output".

================================ CROSS-CHECK ===============================
The headline is verified by a SECOND, INDEPENDENT method — a plain shell
pipeline that never runs this file's parser:

    for g in tests/e2e/*.expected.log; do
      awk -F' -> ' '/ -> h/ && (/^cq_template_/ || /^cqrt_qram_load_/) {print NR, $2}' "$g" \
      | while read -r n h; do
          tail -n "+$((n+1))" "$g" | grep -q "\\b$h\\b" || echo "$g $h"
        done
    done | wc -l

`--crosscheck` runs exactly that pipeline and FAILS LOUDLY on any disagreement,
so the two methods cannot drift apart silently.

================================== RE-RUN ==================================
    python3 tools/record_census/census_03_orphan_rails.py --crosscheck \
        --json docs/prd/record-family/census-0.3-orphan-rails.json
"""

import argparse
import glob
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import census_common as cc  # noqa: E402

fpc = cc.fpc

LINE_RE = re.compile(r"^([A-Za-z_][\w.$]*)\((.*)\)(?:\s*->\s*(.+))?$")
RAIL_RE = re.compile(r"\bh(\d+)\b")
QRAM_LOAD_RE = re.compile(rf"^cqrt_qram_load_{fpc._W}$")
TAPE_WRITE_RE = re.compile(rf"^cqrt_tape_write_{fpc._W}(_controlled)?$")


def family(sym):
    """Producer opcode family for the split, e.g. 'icmp', 'zext_i32_to_i64'."""
    if QRAM_LOAD_RE.match(sym):
        return "qram_load"
    if sym.startswith("cq_template_"):
        stem = sym[len("cq_template_"):]
        for suf in ("_inv", "_unc"):
            if stem.endswith(suf):
                stem = stem[: -len(suf)]
        # drop the trailing shape marker and the width, keep the opcode(+pred)
        stem = re.sub(r"_(hl|lh|qq)$", "", stem)
        stem = re.sub(rf"_{fpc._W}(_to_{fpc._W})?$", "", stem)
        stem = re.sub(rf"_{fpc._W}$", "", stem)
        return stem or sym
    return sym


def sweep_golden(path):
    lines = [l.rstrip("\n") for l in open(path, errors="replace")]
    defs = []            # (lineno0, sym, rail, kind)
    for i, ln in enumerate(lines):
        m = LINE_RE.match(ln.strip())
        if not m:
            continue
        sym, res = m.group(1), (m.group(3) or "").strip()
        rm = re.fullmatch(r"h(\d+)", res)
        if not rm:
            continue
        rail = "h" + rm.group(1)
        if TAPE_WRITE_RE.match(sym):
            kind = "tape"
        elif QRAM_LOAD_RE.match(sym):
            kind = "record"
        elif sym.startswith("cq_template_"):
            kind = "inv" if sym.endswith("_inv") else "record"
        else:
            continue     # cqrt_alloc_* etc — excluded per iwr7
        defs.append((i, sym, rail, kind))
    # LAST line on which each rail name appears, in one pass. (Equivalent to
    # "is it mentioned after line i" but linear rather than quadratic — the
    # libm goldens run to thousands of lines with hundreds of definitions.)
    last = {}
    for i, ln in enumerate(lines):
        for m in RAIL_RE.finditer(ln):
            last["h" + m.group(1)] = i
    orphans = [(i, sym, rail, kind) for (i, sym, rail, kind) in defs
               if last.get(rail, -1) <= i]

    # ---- the WIDER population, reported beside the orphan headline ---------
    # An orphan is "never mentioned again". The Inc-5 (M-B) target is strictly
    # bigger: a template/qram-minted rail that is never DISCHARGED — no `_unc`
    # naming it in the out slot, and no `cqrt_free` of it — EVEN IF it is
    # mentioned again (as a compare operand, a route source, an `_unc`'s
    # SOURCE...). bd 6uqc's whole point is that such a rail is a live basis
    # record; the orphan definition (iwr7's) cannot see it, because the chain's
    # consumers keep it mentioned. Counted separately, never merged.
    discharged, measured = set(), set()
    for ln in lines:
        m = LINE_RE.match(ln.strip())
        if not m:
            continue
        sym, argtxt = m.group(1), m.group(2)
        first = argtxt.split(",")[0].strip() if argtxt else ""
        if sym == "cqrt_free":
            discharged.add(first)
        elif sym.endswith("_unc") and re.fullmatch(r"h\d+", first):
            discharged.add(first)
        elif re.fullmatch(rf"cqrt_measure_{fpc._W}", sym):
            measured.add(first)
    undischarged = [(i, sym, rail, kind) for (i, sym, rail, kind) in defs
                    if kind in ("record", "inv")
                    and rail not in discharged and rail not in measured]
    return lines, defs, orphans, undischarged, measured


def crosscheck(repo):
    """The independent shell pipeline from the docstring. -> total orphan count
    over `record` + `inv` producers (the shell version does not distinguish
    them, so the python side is compared on the same union)."""
    script = r'''
set -e
cd "$1"
for g in tests/e2e/*.expected.log; do
  awk '
    { L[NR] = $0 }
    / -> h/ && (/^cq_template_/ || /^cqrt_qram_load_/) {
        split($0, p, " -> "); r = p[2]
        if (r ~ /^h[0-9]+$/) { D[++nd] = NR; R[nd] = r }
    }
    END {
        for (i = 1; i <= nd; i++) {
            found = 0
            for (j = D[i] + 1; j <= NR; j++)
                if (L[j] ~ ("(^|[^0-9A-Za-z_])" R[i] "([^0-9A-Za-z_]|$)")) { found = 1; break }
            if (!found) n++
        }
        print n + 0
    }' "$g"
done | awk '{s += $1} END {print s + 0}'
'''
    out = subprocess.run(["bash", "-c", script, "_", repo],
                         capture_output=True, text=True, check=True)
    return int(out.stdout.strip())


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--json")
    ap.add_argument("--repo", default=cc.REPO)
    ap.add_argument("--crosscheck", action="store_true")
    args = ap.parse_args(argv)

    goldens = sorted(glob.glob(os.path.join(args.repo, "tests", "e2e",
                                            "*.expected.log")))
    per_golden, fam, kindcount = {}, {}, {"record": 0, "inv": 0, "tape": 0}
    total_defs = 0
    eof = 0
    undis_total, undis_fam, undis_per = 0, {}, {}
    for g in goldens:
        lines, defs, orph, undis, measured = sweep_golden(g)
        undis_total += len(undis)
        for _, usym, _, _ in undis:
            undis_fam[family(usym)] = undis_fam.get(family(usym), 0) + 1
        if undis:
            undis_per[os.path.basename(g)] = len(undis)
        total_defs += len(defs)
        rec = [o for o in orph if o[3] == "record"]
        inv = [o for o in orph if o[3] == "inv"]
        tape = [o for o in orph if o[3] == "tape"]
        kindcount["record"] += len(rec)
        kindcount["inv"] += len(inv)
        kindcount["tape"] += len(tape)
        for i, sym, rail, kind in rec + inv:
            if i == len(lines) - 1:
                eof += 1
            fam.setdefault(family(sym), {"record": 0, "inv": 0})[kind] += 1
        if rec or inv:
            per_golden[os.path.basename(g)] = {
                "record_orphans": [{"line": i + 1, "sym": s, "rail": r}
                                   for i, s, r, k in rec],
                "inv_orphans": [{"line": i + 1, "sym": s, "rail": r}
                                for i, s, r, k in inv],
                "tape_kept": len(tape),
            }

    report = {
        "goldens": len(goldens),
        "rail_definitions_scanned": total_defs,
        "orphan_records": kindcount["record"],
        "orphan_inv_mints": kindcount["inv"],
        "tape_rails_excluded_by_design": kindcount["tape"],
        "goldens_with_orphans": len(per_golden),
        "orphans_at_eof": eof,
        "by_producer_family": fam,
        "undischarged_records": undis_total,
        "undischarged_by_family": undis_fam,
        "undischarged_per_golden": undis_per,
        "per_golden": per_golden,
    }

    print(f"goldens scanned                          : {report['goldens']}")
    print(f"template/qram rail definitions           : {total_defs}")
    print(f"ORPHAN records (cq_template_* / qram_load): "
          f"{report['orphan_records']}")
    print(f"ORPHAN `_inv` phantom mints              : "
          f"{report['orphan_inv_mints']}")
    print(f"tape rails (kept BY DESIGN, excluded)    : "
          f"{report['tape_rails_excluded_by_design']}")
    print(f"goldens containing >=1 orphan            : "
          f"{report['goldens_with_orphans']}")
    print(f"  of which defined on the LAST line      : {eof}")
    print(f"\nWIDER POPULATION (Inc-5 target, NOT the orphan headline):")
    print(f"  template/qram rails never DISCHARGED     : {undis_total}"
          f"   in {len(undis_per)} goldens")
    print("  top families: " + ", ".join(
        f"{k}={undis_fam[k]}" for k in sorted(undis_fam, key=lambda k: -undis_fam[k])[:12]))
    print("\nby producer family (orphans):")
    for k in sorted(fam, key=lambda k: -(fam[k]['record'] + fam[k]['inv'])):
        v = fam[k]
        print(f"  {k:34s} record={v['record']:4d}  inv={v['inv']:4d}")
    print("\nper golden (record orphans, then _inv):")
    for g in sorted(per_golden):
        v = per_golden[g]
        print(f"  {g}: {len(v['record_orphans'])} record, "
              f"{len(v['inv_orphans'])} inv")
        for o in v["record_orphans"]:
            print(f"      :{o['line']} {o['sym']} -> {o['rail']}")
        for o in v["inv_orphans"]:
            print(f"      :{o['line']} [inv] {o['sym']} -> {o['rail']}")

    if args.crosscheck:
        shell = crosscheck(args.repo)
        mine = report["orphan_records"] + report["orphan_inv_mints"]
        print(f"\nCROSS-CHECK (independent shell pipeline): {shell}  "
              f"(python: {mine})")
        if shell != mine:
            print("MISMATCH — the two methods disagree; do not quote either "
                  "number until this is resolved.")
            return 2
        print("cross-check AGREES")
    if args.json:
        with open(args.json, "w") as f:
            json.dump(report, f, indent=1, sort_keys=True)
        print(f"\nwrote {args.json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
