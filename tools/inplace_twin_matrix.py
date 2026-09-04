#!/usr/bin/env python3
"""inplace_twin_matrix.py — the CONTROLLED-Ry-EQUALS-ROUTED-Rz witness, as a MATRIX.

bd test_C_libtooling-drbq (control-in-place Ry arms), Rule-13 ROUND 2. Committed
as an INSTRUMENT, not as a gate — see "HOW TO RUN IT" and "WHAT IT CANNOT
WITNESS" below before quoting any result from it.

WHY THIS EXISTS. Increment 1's correctness claim is one sentence: the in-place
emitter's stream is the trusted swap-route stream with the five-line route
   cqrt_alloc_<W>(0) -> rail ; cqrt_cswap(f,r,rail) ; cqrt_rz_<W>(rail,t)
   ; cqrt_cswap(f,r,rail) ; cqrt_free(rail)
collapsed to the single `cqrt_ry_<W>_controlled(f, r, t)`, and NOTHING ELSE
MOVED. CQ has no simulator (Rule 2, owner decision 2026-06-10), so that
byte-level twin identity is the only witness available — exactly the argument
`tools/loop_twin_matrix.py` makes for the rolled loop.

Both ROUND-1 confirmed defects were CROSSED-AXIS shapes that single-axis probes
missed:
  * L3 §1 / notes finding L — DERIVED base (mul/add/xor/cast) x a POST-REGION
    consumer. Either axis alone was covered by a green fixture; the product was
    a use-after-free plus a dirty free of an entangled rail.
  * L2 §1 / notes finding K — a CLASSICAL join phi x a non-`lowerOps` SINK
    (measure/ret/tape/call/invert). Either alone declined; the product silently
    read the post-Ry register.
So this instrument does not walk one axis at a time. It generates the union of
every 2-DIMENSIONAL PLANE through a default cell (all-pairs coverage over five
axes), which is the smallest design that can see a two-axis interaction at all.

WHAT ONE CELL IS. One C program in two spellings that differ in EXACTLY the
region's arm gate:
    Ry side : if (cond) { r = cq_theta(r, 0.9); }   <- the increment under test
    Rz side : if (cond) { r = cq_phi  (r, 0.9); }   <- the trusted swap route
Every other angle in the generated program is distinct from the substitutable
set {0.9, 0.4, 0.3, 0.35}, so the reducer can tell a region-under-test's route
from a route that is a genuine phase region in BOTH spellings (the `route2`
consumer is exactly that control).

WHAT IS CHECKED, per cell:
 (1) DISPOSITION. Ry accepts / Rz declines is SUSPICIOUS (the trusted path
     refused a shape the new one took). Rz accepts / Ry declines is an
     OVER-DECLINE — a scope fact, not a bug, UNLESS it is emission-order
     dependent (round 1 L4 §2).
 (2) PREFIX IDENTITY. Up to and including the last region flag `cqrt_free`, the
     Ry trace must equal the REDUCED Rz trace byte-for-byte with handles
     renumbered by first appearance. `cqrt_x` brackets, flag mint, strip and
     free must be present, identical, and in the same order.
 (3) SUFFIX CLASS. After the last flag free the two MAY differ, by the freeze
     and only by the freeze (Rule 6: the rotated Ry rail and anything the DAG
     closure marks NotClosed is left allocated; the Rz twin may reverse+free) —
     and, since bd drbq Inc 2a, by ONE further expected shape: a `route2`
     consumer's second phase region is a ROUTE in the pre-2a oracle and a
     CONTROLLED Rz on the build under test, which `reduce_route` deliberately
     does not reduce (its angle is outside `ARM_HEX`, which is what keeps the I1
     count honest). That case is labelled `SUFFIX-2A-COLLAPSE(expected)` and is
     reached only when the suffixes are byte-identical after the OLD one is fully
     reduced — see the note at the classification site.
     Each cell's suffix diff is recorded and classified; a suffix diff that is
     not `Rz-has-extra-lines-only` is a finding.
 (4) INVARIANTS on the accepted Ry side:
       I1 one `cqrt_ry_<W>_controlled` per reduced route (counts must match)
       I2 NO negative angle on any `cqrt_ry_*_controlled` — that is the
          finding-A adjoint signature, and every angle in this generator is
          positive, so a negative one can only have been synthesized
       I3 no `cqrt_free` of a rotated rail (the freeze)
       I4 every region flag's `cqrt_free(f)` is preceded by a `..._unc(f, ...)`
       I5 STRICT `free_pairing_check.py`: 0 violations, 0 unproven

HANDLE NORMALISATION is mandatory, not cosmetic: the Rz side mints one extra
`cqrt_alloc` per route, so every later handle number shifts. Numbering by first
appearance after the reduction makes the two comparable without weakening the
comparison — a REAL reordering still shows as a mismatch.

THE ONE WAY THIS CAN CRY WOLF, recorded before it bites someone: the two sides
are the same source text but `clang -O1` may canonicalize them differently
(`cq_theta` is a taint SOURCE and `cq_phi` is not, so DCE and the angle-select
fold can reach one side only). A DISPOSITION mismatch is therefore reported, not
assumed to be a compiler defect; every one below is reproduced standalone before
it is ranked.

─────────────────────────────────────────────────────────────────────────────────
HOW TO RUN IT (from the repository ROOT; `--root .` is the default)

    python3 tools/inplace_twin_matrix.py --quick          # ~40s, 40 cells
    python3 tools/inplace_twin_matrix.py                  # ~6.5 min, 472 cells
    python3 tools/inplace_twin_matrix.py --triples        # ~3.5 min, 198 cells
    python3 tools/inplace_twin_matrix.py --only c_mul_eq  # one plane
    python3 tools/inplace_twin_matrix.py --list           # cell names, no runs

    # the bd drbq Increment-4 STATE-PREP pool (`sp_*`), a SEPARATE pool with a
    # SEPARATE oracle — see "THE STATE-PREP AXIS" below:
    python3 tools/inplace_twin_matrix.py --stateprep \
            --prep-oracle /path/to/pre-Inc-4/cq-opt --jobs 8
    python3 tools/inplace_twin_matrix.py --stateprep --only sp_s5 --list

⚠ SINCE bd drbq INCREMENT 2a THE `--route-oracle` FLAG IS MANDATORY FOR A MEANINGFUL
RUN, and here is why. This script's oracle was always "the `cq_phi` twin, which
ROUTES". Inc 2a (the §6a Rz control-in-place peephole) lowers the `cq_phi` twin
control-in-place too, so WITHOUT the flag the script compares one in-place stream
against another and the central claim — "the in-place stream IS the routed stream
with the route collapsed" — is no longer being tested at all. It would still print
PREFIX-IDENTICAL, and that green would mean nothing.

    # build the pre-2a oracle ONCE, in a scratch worktree, and keep the path:
    git worktree add /tmp/wt-f92d95e f92d95e
    cmake -S /tmp/wt-f92d95e -B /tmp/wt-build \
          -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
    cmake --build /tmp/wt-build --target cq-opt -j8
    python3 tools/inplace_twin_matrix.py --jobs 8 --route-oracle /tmp/wt-build/ir-pass/cq-opt

With the flag the ORACLE INVERTS and the run makes TWO claims per cell instead of
one. The routed stream comes from the PRE-2a binary; this build's Ry side is
compared to it on the PREFIX as before (the Ry freeze legitimately truncates the
suffix), and this build's Rz side is compared to it on the WHOLE TRACE — prefix AND
suffix — because the Rz stem is TRANSPARENT to uncomputation (PRD §12.1: not a DAG
link, never adjointed, not frozen), so every post-region `_unc`, `cqrt_free` and
adjoint must be byte-for-byte what the route produced. That second claim is the one
the Ry side structurally cannot make, and it is reported in its own tally
(`RZ-COLLAPSE-ONLY` / `RZ-MISMATCH` / `RZ-DISPOSITION-MOVED`). The reduction it uses
is `golden_multiset_audit.reduce_routes`, shared with the Inc-2a golden audit rather
than re-spelt (Rule 14). Cost: one extra `cq-opt` + link + run per cell, so roughly
1.5x the figures above.

Other flags: `--jobs N` (process pool; stage 2b runs in-process), `--keep DIR`
(retain every cell's `.c` / `.ll` / `.s2.ll` for reproduction), `--llvm DIR`
(default `/usr/local/opt/llvm@19/bin`), `--out FILE`. It reads `CQ_LD` if set
(the bd `dgn5` link wrapper) and otherwise falls back to
`build/tests/e2e/cq_link.sh`, then to the clang driver. Requires a built
`build/ir-pass/cq-opt` and the two runtime archives — build with
`cmake --build build -j8` (NEVER `--target CQPass` alone: `cq-opt` is a separate
target from the same sources and a CQPass-only rebuild reports FALSE GREEN).

COST, measured on a quiet 6-physical-core box at `--jobs 8`: full 472 cells
(944 pipelines) ~6.5 min; `--triples` 198 cells ~3.5 min; `--quick` 40 cells
~40 s.

⚠ IT IS NOT A CTEST GATE, DELIBERATELY, AND MUST NOT BE ADDED AS ONE WITHOUT AN
OWNER COST DECISION. The full matrix is roughly three times the whole current
`ctest -j6` band (~130-230 s quiet-box), and Rule 19 exists precisely to stop
reflexive expensive runs. Two more things are owed before it could become a
gate, and they are deliberately NOT done here: (1) a COMMITTED
expected-disposition table plus a `--regenerate` switch, the way
`tools/loop_twin_matrix.expected.txt` does it, so a disposition drift is a RED
rather than something a reader has to notice — today this script prints and
tallies, it does not compare against a baseline; and (2) a decision on the
`invert` cells, which need the two-line `__cq_invert_begin/_end` stub this
harness synthesizes in order to LINK AT ALL (see the blind-spot list below).

─────────────────────────────────────────────────────────────────────────────────
THE STATE-PREP AXIS (`--stateprep`, bd test_C_libtooling-drbq Increment 4 /
drbq.5) — A SEPARATE POOL WITH A SEPARATE ORACLE

Increment 4 admits a `cq_theta` whose arg-0 is CLASSICAL: controlled STATE PREP
(`int r = 0; if (q == 5) r = cq_theta(0, 0.9);`). Its arm MINTS A FRESH RAIL
instead of relabelling a live one, so the "collapse the five-line route" claim
this file was built for does not apply and neither does its `cq_phi` oracle. The
`sp_*` pool therefore states a DIFFERENT claim, against a DIFFERENT reference:

    SUBJECT : T r = SEED;                 if (cond) { r = cq_theta(SEED, 0.9); }
    TWIN    : T r = cq_theta(SEED, 0.0);  if (cond) { r = cq_theta(r,    0.9); }

The twin is the Increment-1 CHAINED shape on a rail seeded by an explicit
`Ry(0)`, and a PRE-Increment-4 binary already lowers it — MEASURED, on `b506b3b`,
for `SEED` 0 and 5, for `==` and `!=`, and at `double`. `--prep-oracle` names
that binary and the twin is built with it; the subject is built with the build
under test. Two different commits, two different programs: an Increment-4 change
cannot flatter its own witness through either.

THE CLAIM, and it is exactly two lines long: the subject's trace equals the
twin's after
  (i)  DELETING `cqrt_ry_<W>(h, 0x0p+0)` — Ry(0) is the identity matrix; and
  (ii) MOVING `cqrt_alloc_<W>(SEED) -> h` to immediately before the first
       `cqrt_ry_<W>_controlled(f, h, .)` naming `h` — a fresh rail is a wire no
       earlier gate names, so its allocation commutes past all of them,
with handles renumbered by first appearance as everywhere else in this file.
Both rewrites are PHYSICAL IDENTITIES of the trace algebra, not steps of the
lowering — which is the bd [`by-difference-twin-blind-to-arithmetic`] discipline
applied before the fact rather than after it. The twin really does allocate a
rail and really does rotate it by zero; those two gates are the entire claimed
difference, and `reduce_prep` is the claim written out.

VERDICTS (`classify_prep`): DECLINE-BOTH · DECLINE-BOTH-DIFF ·
SUBJECT-DECLINES-TWIN-ACCEPTS (the expected PRE-Increment-4 reading of every
in-scope cell) · IDENTICAL (the Increment-4 success verdict) · MISMATCH (a
finding) · SUBJECT-ACCEPTS-TWIN-DECLINES (SUSPICIOUS — the new path took a shape
the long-cleared chained path refuses) · HARNESS-ERROR.

WHAT THE `s5` SEED CELL IS FOR, because a reader will otherwise take it for a
duplicate of `s0`. `clang -O1` propagates equalities: on the successor where
`cq0 == 5` is a theorem, every use of `cq0` there becomes the literal `5`. So

    T r = 5; if (cq0 == 5) { r = cq_theta(5,   0.9); }   <- the sp_s5 subject
    T r = 5; if (cq0 == 5) { r = cq_theta(cq0, 0.9); }   <- an in-place Ry on the
                                                           CONDITION register,
                                                           which PRD §4 R4 forbids

compile to the SAME MODULE — measured for this increment, whole-module `diff`,
only `source_filename` differs. `s5` is the AMBIGUITY cell: whatever Increment 4
does to it, it does to a program it must decline. `s0` is the control (the arm
edge proves `cq0 == 5`, and `0 != 5`, so no fold could have produced that seed).
⚠ And note what `s5` is NOT: here the seed and the compare literal belong to
DIFFERENT REGISTERS — `r` is rotated, `cq0` is compared, and that separation IS
R4 — so a fence spelled "the seed equals the compare literal" over-declines this
cell on a coincidence of numerals. The ambiguity is real regardless, because the
fold reads identically either way; a fence has to be stated over what the ARM
EDGE PROVES ABOUT THE CONDITION HANDLE, and then `s5` is a priced over-decline
rather than an accident.

WHAT THIS AXIS CANNOT WITNESS, on top of everything in the next section:
  * ITS ORACLE IS A DIFFERENT PROGRAM, NOT A DIFFERENT LOWERING. The twin is a
    chained rotation; the subject is a state prep. So the axis proves "the prep
    stream is the chained stream minus a seed rotation" and CANNOT prove that
    accepting the prep shape was legitimate — the seed-identity fence on the
    merge phi's pred incoming, and the `s5` ambiguity above, are exactly the
    obligations the twin is exempt from. They belong to the lit family.
  * `ifelse2` IS EXCLUDED from the pool: its else arm rotates a SECOND register
    chained-style, so the cell would be a mixture of the two shapes rather than a
    cell of either. `ifelse` is KEPT and is informative — `clang -O1` merges its
    two arms into ONE call with a `select` on the ANGLE (bd drbq Inc 2b), for
    BOTH sides, so the cell measures the angle-select path's own state-prep
    disposition (`classifyAngleSelect` S3).
  * THE SECOND REGION in a `clsbetween` cfg or a `region2` consumer is a CHAINED
    rotation on the prepped register, not a second prep. Deliberate: two preps in
    a row is a data mux (the second region's pred-edge incoming is the first
    region's merge phi, never a constant), which declines for a reason unrelated
    to the crossing those cells exist to measure.
  * NO COMMITTED EXPECTED TABLE — same status as the rest of this file (bd
    drbq.9). It prints and tallies; it does not compare against a baseline, and
    it is NOT a ctest entry.

─────────────────────────────────────────────────────────────────────────────────
WHAT IT CANNOT WITNESS — read this before quoting a green run

  * THE ORACLE IS Rz, SO EVERY FENCE THAT IS Ry-ONLY IS INVISIBLE TO IT. The
    comparison proves "the in-place stream is the route stream, collapsed". It
    CANNOT prove "the collapse was legitimate for this shape", because the two
    things that make it legitimate — R4 (the rotated wire is disjoint from every
    condition wire, so the flag strip is valid) and R6 (no post-region read of a
    pre-Ry record) — are exactly the fences the `cq_phi` twin is EXEMPT from. A
    shape that violated R4 would emit a prefix byte-identical to the route's and
    still be wrong. R4 was therefore attacked directly, by hand, in the round-2
    review (every alias spelling either declines or is genuinely a fresh rail);
    that work is NOT in this script and re-running it green does not repeat it.
  * THE `invert` CELLS LINK AGAINST A SYNTHESIZED STUB.
    `__cq_invert_begin/_end` are bare externs with NO runtime definition anywhere
    in the tree (Phase 8 is unimplemented and the pass leaves the markers in
    place), so those cells would not link at all. The stub is a HARNESS
    accommodation; it changes nothing the compiler emitted, but a green `invert`
    cell is NOT evidence that a `cq_invert` bracket links in the real pipeline.
    It does not.
  * IT IS ALL-PAIRS, so it is blind to a genuine 3-way interaction by
    construction. `--triples` runs a hand-picked 3-way slice for that reason;
    neither is exhaustive.
  * DISPOSITION mismatches are reported, never assumed to be defects — see the
    cry-wolf note above. Only a PREFIX mismatch has no such escape.
  * It says nothing about anything outside the generated axis set: nested
    regions, `switch`, loops, QRAM, the 6.5 classical-call arm.

RUN (legacy spelling, still accepted):
  python3 inplace_twin_matrix.py --root /path/to/CQ_lang [--jobs 6]
      [--only <substr>] [--list] [--keep <dir>]
"""

import argparse
import concurrent.futures
import itertools
import os
import re
import shutil
import subprocess
import sys
import tempfile

# ─────────────────────────────── THE AXES ────────────────────────────────────
# Five axes. The generated set is the union over every PAIR of axes of the full
# 2-D plane through the default cell (all-pairs), plus a hand set of round-1
# reproducers as regression cells.

DEFAULT = dict(base="src", cond="eq", cfg="diamond", cons="meas", width="i32")

WIDTH = {
    #        C type          a literal   a narrower/other type for the cast base
    "i32": ("int",           "5",  "signed char", "sc"),
    "i8":  ("signed char",   "5",  "int",         "i"),
    "i64": ("long long",     "5",  "signed char", "sc"),
    "f64": ("double",        "5.0","int",         "i"),
}

BASES  = ["src", "mul", "add", "xor", "cast", "phial", "chain"]
CONDS  = ["eq", "ne", "gt", "ge", "aliaseq", "fcmp"]
CFGS   = ["diamond", "negated", "ifelse", "ifelse2", "clsbefore", "clsbetween"]
# `dead*` are the ROUND-1 L3 axis: a DEAD reversible chain off the register whose
# whole-DAG reversal point lands AFTER the region's flag free. That is the half of
# the L3/finding-L crossed pair that no single-axis probe carried, and it is the
# only consumer family in which the FREEZE is observable at all.
CONS   = ["none", "meas", "aliasmeas", "launder", "ret", "mul3", "spine",
          "theta_after", "phi_after", "region2", "route2", "value2", "printf",
          "deadadd", "deadmul", "call", "invert"]
WIDTHS = ["i32", "i8", "i64", "f64"]

AXES = [("base", BASES), ("cond", CONDS), ("cfg", CFGS),
        ("cons", CONS), ("width", WIDTHS)]

# ── THE STATE-PREP AXIS (bd test_C_libtooling-drbq Increment 4, drbq.5) ───────
# A SEPARATE POOL, not a sixth axis on the product above, because its two SIDES
# are different programs from the five-axis cells' two sides. Everything in this
# block is inert unless `--stateprep` is passed; `cells()`, `quick_cells()` and
# `triple_cells()` are byte-unchanged (proven by diffing `--list` before and
# after, not asserted).
#
# WHAT ONE CELL IS. Increment 4 admits a `cq_theta` whose arg-0 is CLASSICAL —
# controlled STATE PREP — so its arm mints a FRESH rail instead of relabelling a
# live one:
#     SUBJECT : T r = SEED;                 if (cond) { r = cq_theta(SEED, 0.9); }
#     TWIN    : T r = cq_theta(SEED, 0.0);  if (cond) { r = cq_theta(r,    0.9); }
# The twin is the Increment-1 CHAINED shape on a rail seeded by an explicit
# `Ry(0)`, and it is what the ORACLE — a PRE-Increment-4 binary — already lowers.
# The claim under test is that Increment 4's stream IS that stream with exactly
# two lines moved or removed, and nothing else.
#
# THE REDUCTION, and why it is not the transformation under test. `reduce_prep`
# below applies two rewrites to the TWIN's trace:
#   (i)  DELETE `cqrt_ry_<W>(h, 0x0p+0)` — a ZERO-ANGLE Ry is the identity
#        matrix, so deleting it changes no state at all;
#   (ii) MOVE `cqrt_alloc_<W>(SEED) -> h` to immediately before the first
#        `cqrt_ry_<W>_controlled(f, h, ·)` naming `h` — a fresh-rail allocation
#        acts on a wire no earlier gate names, so it COMMUTES with all of them.
# Both are PHYSICAL IDENTITIES of the trace algebra, not steps of the lowering.
# That distinction is the bd [`by-difference-twin-blind-to-arithmetic`] lesson
# applied in advance: an identity witness must not share the transformation it
# witnesses. This one does not — the twin ALLOCATES A RAIL AND ROTATES IT BY
# ZERO, two real gates that Increment 4 will never emit, and the reduction is
# precisely the statement that those two gates are the whole difference.
#
# ⚠ THE ORACLE IS A DIFFERENT COMMIT FROM `--route-oracle`'s. That flag wants the
# PRE-2a binary (`f92d95e`), in which the `cq_phi` twin still ROUTES; this axis
# wants the PRE-Increment-4 binary (`b506b3b`), in which the CHAINED twin already
# lowers. They are not the same build, so the axis takes its own `--prep-oracle`
# rather than overloading one flag with two meanings. `--prep-oracle` falls back
# to `--route-oracle` when only that is given, and to the build under test with a
# loud warning when neither is — a run in that state proves nothing about
# Increment 4 and says so.
#
# THE SEED AXIS IS WHERE THE INTERESTING CELL IS, and it is worth reading before
# quoting an `s5` verdict. `clang -O1` propagates an equality: on the successor
# where `cq0 == 5` is a theorem, EVERY use of `cq0` there is replaced by the
# literal `5`. So the SUBJECT source
#       T r = 5;  if (cq0 == 5) { r = cq_theta(5, 0.9); }
# is TEXTUALLY INDISTINGUISHABLE, whole-module, from
#       T r = 5;  if (cq0 == 5) { r = cq_theta(cq0, 0.9); }
# — an in-place Ry on the CONDITION register, which PRD §4 R4 forbids outright
# (after it, `icmp_..._unc` recomputes the flag against a relabelled register).
# MEASURED on the ORACLE, in the probe family for this increment: those two C
# programs produce `.ll` files differing only in `source_filename`. So an `s5`
# cell is the AMBIGUITY cell: whatever Increment 4 does to it, it does to a
# program it must decline. `s0` is the unambiguous control — the arm edge proves
# `cq0 == 5`, and `0 != 5`, so no fold could have produced that seed.
#
# NOTE WHAT `s5` IS *NOT*. The seed and the compare literal here belong to
# DIFFERENT REGISTERS (`r` is rotated, `cq0` is compared — that separation IS
# R4), so a fence keyed on "the seed equals the compare literal" over-declines
# this cell for a coincidence of numerals. The ambiguity is real anyway, for the
# reason above: the fold reads the same either way. A fence has to be stated over
# what the ARM EDGE PROVES about the CONDITION HANDLE, and then `s5` is a
# deliberate, priced over-decline rather than an accident.
PREP_SEEDS = {
    #        i32   i8    i64   f64
    "s0": {"i32": "0", "i8": "0", "i64": "0", "f64": "0.0"},
    "s5": {"i32": "5", "i8": "5", "i64": "5", "f64": "5.0"},
}
PREP_SEEDNAMES = list(PREP_SEEDS)

# All-pairs again, over the FOUR axes that still mean something for a prep cell.
# `base` is gone by construction (a state prep has no derived base — its arg-0 is
# a literal), and `ifelse2` is excluded because its else arm rotates a SECOND
# register `r2` chained-style, which would make the cell a mixture of the two
# shapes rather than a cell of either.
PREP_CFGS = [g for g in CFGS if g != "ifelse2"]
PREP_DEFAULT = dict(prep="s0", cond="eq", cfg="diamond", cons="meas", width="i32")
PREP_AXES = [("prep", PREP_SEEDNAMES), ("cond", CONDS), ("cfg", PREP_CFGS),
             ("cons", CONS), ("width", WIDTHS)]


def prep_cells():
    """All-pairs over PREP_AXES: the union of every 2-D plane through
    `PREP_DEFAULT`. Same design as `cells()` and for the same reason — both
    round-1 Increment-1 defects were TWO-AXIS crossings."""
    out, seen = [], set()

    def add(c):
        k = tuple(sorted(c.items()))
        if k not in seen:
            seen.add(k)
            out.append(dict(c))

    add(PREP_DEFAULT)
    for (na, va), (nb, vb) in itertools.combinations(PREP_AXES, 2):
        for a, b in itertools.product(va, vb):
            c = dict(PREP_DEFAULT)
            c[na], c[nb] = a, b
            if prep_legal(c):
                add(c)
    return out


def prep_legal(c):
    return True

# Angles the twin substitution rewrites (`cq_theta` <-> `cq_phi`). Every OTHER
# angle in a generated program is outside this set so the reducer can never
# collapse a route that is a phase region on both sides.
ARM_ANGLES = ["0.9", "0.4", "0.3", "0.35"]


# The hand-picked THREE-WAY slice (was `triples.py`, folded in here so there is
# ONE instrument file). All-pairs is the right design for the round-1 defect
# class — both defects were 2-way crossings — but it is blind to a 3-way one by
# construction, so these run the most dangerous-looking triples: a DERIVED base
# x polarity-or-CFG x a consumer that engages the whole-DAG spine.
TRIPLE_BASES = ["mul", "add", "xor", "cast", "chain", "phial"]
TRIPLE_CFGS  = ["negated", "clsbefore", "clsbetween"]
TRIPLE_CONS  = ["deadadd", "deadmul", "spine", "region2", "theta_after",
                "aliasmeas"]
TRIPLE_WIDTHS = ["i32", "f64"]

# `--quick`: the smallest set that still crosses both round-1 defect axes (a
# DERIVED base x a spine-engaging consumer, and the classical-join launder), in
# under a minute. It is a SMOKE TEST — a green `--quick` is not a green matrix.
QUICK_BASES = ["src", "mul", "add", "cast"]
QUICK_CONS  = ["meas", "launder", "spine", "deadmul", "region2"]
QUICK_WIDTHS = ["i32", "f64"]


def triple_cells():
    out = []
    for b, g, k, w in itertools.product(TRIPLE_BASES, TRIPLE_CFGS, TRIPLE_CONS,
                                        TRIPLE_WIDTHS):
        c = dict(DEFAULT)
        c.update(base=b, cfg=g, cons=k, width=w)
        if legal(c):
            out.append(c)
    return out


def quick_cells():
    out = []
    for b, k, w in itertools.product(QUICK_BASES, QUICK_CONS, QUICK_WIDTHS):
        c = dict(DEFAULT)
        c.update(base=b, cons=k, width=w)
        if legal(c):
            out.append(c)
    return out


def cells():
    """All-pairs: the union of every 2-D plane through DEFAULT."""
    out = []
    seen = set()

    def add(c):
        k = tuple(sorted(c.items()))
        if k not in seen:
            seen.add(k)
            out.append(dict(c))

    add(DEFAULT)
    for (na, va), (nb, vb) in itertools.combinations(AXES, 2):
        for a, b in itertools.product(va, vb):
            c = dict(DEFAULT)
            c[na], c[nb] = a, b
            if legal(c):
                add(c)
    return out


def legal(c):
    if c["width"] == "f64" and c["base"] == "xor":
        return False        # no `^` on double
    return True


def name(c):
    # TWO grammars, told apart by the `prep` key, which no five-axis cell has —
    # so a state-prep cell can never collide with a committed `c_...` name and
    # `--only c_` / `--only sp_` each select exactly one pool.
    if "prep" in c:
        return "sp_%s_%s_%s_%s_%s" % (c["prep"], c["cond"], c["cfg"], c["cons"],
                                      c["width"])
    return "c_%s_%s_%s_%s_%s" % (c["base"], c["cond"], c["cfg"], c["cons"],
                                 c["width"])


# ────────────────────────── THE C GENERATOR ──────────────────────────────────
# `ARM(` is the substitution point: cq_theta on the Ry side, cq_phi on the Rz
# side. NOTHING ELSE in the program changes between the two sides.

def gen(c, arm):
    """One side of one cell.

    `arm` is the ARM-GATE spelling for a five-axis cell (`cq_theta` = the Ry side
    under test, `cq_phi` = the routed Rz oracle) and the SIDE NAME for a
    state-prep cell (`prep` = the Increment-4 subject, `twin` = the Increment-1
    chained reference). See `PREP_SEEDS` for what the two prep sides are."""
    T, LIT, CT, _ = WIDTH[c["width"]]
    fp = c["width"] == "f64"
    one = "1.0" if fp else "1"
    three = "3.0" if fp else "3"
    five = "5.0" if fp else "5"
    seven = "7.0" if fp else "7"
    nine = "9.0" if fp else "9"

    L = []            # body statements
    M = []            # measure expressions folded into the return
    extra = []        # bare `(void)cq_measure(x);` statements

    # ── condition register ───────────────────────────────────────────────────
    if c["cond"] == "fcmp":
        L.append("    double cf = 0.5; cf = cq_theta(cf, 0.5);")
        cond = "cf > 0.5"
        M.append("(int)cq_measure(cf)")
    else:
        L.append("    int cq0 = 3; cq0 = cq_theta(cq0, 0.5);")
        cv = "cq0"
        if c["cond"] == "aliaseq":
            L.append("    int cqa = cq_phi(cq0, 0.07);")
            cv = "cqa"
        cond = {"eq": "%s == 5", "ne": "%s != 5", "gt": "%s > 5",
                "ge": "%s >= 5", "aliaseq": "%s == 5"}[c["cond"]] % cv
        M.append("(int)cq_measure(cq0)")

    # ── base register `r` ────────────────────────────────────────────────────
    #
    # `A0` is the arg-0 of the REGION-UNDER-TEST's arm gate. For every five-axis
    # cell it is the register `r` — a CHAINED rotation — so the generated text is
    # byte-identical to what it was before the state-prep pool existed. For a
    # state-prep SUBJECT it is the classical SEED literal, and that ONE token is
    # the entire difference between the two shapes.
    #
    # It is substituted at the 0.9 and 0.4 sites only. The SECOND region a
    # `clsbetween` cfg or a `region2` consumer builds stays a CHAINED rotation on
    # the prepped register, deliberately: two preps in a row is a data mux (the
    # second region's pred-edge incoming is the first region's merge phi, not a
    # constant) and would decline for a reason that has nothing to do with the
    # crossing those cells exist to measure.
    A0 = "r"
    prep = c.get("prep")
    if prep:
        sd = "(%s)%s" % (T, PREP_SEEDS[prep][c["width"]])
        if arm == "prep":
            L.append("    %s r = %s;" % (T, sd))
            A0 = sd
        else:
            # THE TWIN. `cq_theta(SEED, 0.0)` is a REAL allocation plus a REAL
            # zero-angle rotation — two gates Increment 4 never emits — and
            # `reduce_prep` removes exactly those two and nothing else.
            L.append("    %s r = cq_theta(%s, 0.0);" % (T, sd))
        arm = "cq_theta"
    b = c.get("base")
    if prep:
        pass
    elif b == "src":
        L.append("    %s r = (%s)%s; r = cq_theta(r, 0.25);" % (T, T, seven))
    elif b in ("mul", "add", "xor"):
        op = {"mul": "*", "add": "+", "xor": "^"}[b]
        L.append("    %s p = (%s)%s; p = cq_theta(p, 0.25);" % (T, T, seven))
        L.append("    %s r = (%s)(p %s (%s)%s);" % (T, T, op, T, five))
    elif b == "cast":
        L.append("    %s pc = (%s)%s; pc = cq_theta(pc, 0.25);" % (CT, CT, seven))
        L.append("    %s r = (%s)pc;" % (T, T))
    elif b == "phial":
        L.append("    %s p = (%s)%s; p = cq_theta(p, 0.25);" % (T, T, seven))
        L.append("    %s r = cq_phi(p, 0.05);" % T)
    elif b == "chain":
        L.append("    %s r = (%s)%s; r = cq_theta(r, 0.25); r = cq_theta(r, 0.06);"
                 % (T, T, seven))

    # ── consumer PRE fragments (they must sit before the region) ─────────────
    if c["cons"] == "aliasmeas":
        L.append("    %s ra = cq_phi(r, 0.09);" % T)
    elif c["cons"] == "launder":
        # The round-1 L2 launder: an ordinary CLASSICAL join phi over the base.
        L.append("    %s rm; if (cc) { rm = cq_phi(r, 0.1); } else { rm = r; }"
                 % T)

    # ── CFG pre ──────────────────────────────────────────────────────────────
    if c["cfg"] in ("clsbefore", "clsbetween"):
        L.append("    if (cc) { gsink = 1; }")

    # ── THE REGION ───────────────────────────────────────────────────────────
    cexpr = "!(%s)" % cond if c["cfg"] == "negated" else cond
    if c["cfg"] == "ifelse":
        L.append("    if (%s) { r = ARM(%s, 0.9); } else { r = ARM(%s, 0.4); }"
                 % (cexpr, A0, A0))
    elif c["cfg"] == "ifelse2":
        L.append("    %s r2 = (%s)%s; r2 = cq_theta(r2, 0.11);" % (T, T, nine))
        L.append("    if (%s) { r = ARM(%s, 0.9); } else { r2 = ARM(r2, 0.4); }"
                 % (cexpr, A0))
        extra.append("    (void)cq_measure(r2);")
    else:
        L.append("    if (%s) { r = ARM(%s, 0.9); }" % (cexpr, A0))

    if c["cfg"] == "clsbetween":
        L.append("    if (cc) { gsink = 2; }")
        L.append("    int cq2 = 4; cq2 = cq_theta(cq2, 0.6);")
        L.append("    if (cq2 == 4) { r = ARM(r, 0.3); }")
        M.append("(int)cq_measure(cq2)")

    # ── consumer POST fragments ──────────────────────────────────────────────
    k = c["cons"]
    rt = "int"
    ret = None
    if k == "none":
        pass
    elif k == "meas":
        M.append("(int)cq_measure(r)")
    elif k == "aliasmeas":
        M.append("(int)cq_measure(ra)")
        M.append("(int)cq_measure(r)")
    elif k == "launder":
        M.append("(int)cq_measure(rm)")
        M.append("(int)cq_measure(r)")
    elif k == "ret":
        rt = T
        ret = "r"
    elif k == "mul3":
        L.append("    %s s = (%s)(r * (%s)%s);" % (T, T, T, three))
        M.append("(int)cq_measure(s)")
    elif k == "spine":
        L.append("    %s s = (%s)(r + (%s)%s);" % (T, T, T, one))
        L.append("    %s t = (%s)(s * (%s)%s);" % (T, T, T, three))
        M.append("(int)cq_measure(t)")
    elif k == "theta_after":
        L.append("    r = cq_theta(r, 0.08);")
        M.append("(int)cq_measure(r)")
    elif k == "phi_after":
        L.append("    r = cq_phi(r, 0.08);")
        M.append("(int)cq_measure(r)")
    elif k in ("region2", "route2", "value2"):
        L.append("    int cz = 4; cz = cq_theta(cz, 0.6);")
        if k == "region2":
            L.append("    if (cz == 4) { r = ARM(r, 0.35); }")
        elif k == "route2":
            L.append("    if (cz == 4) { r = cq_phi(r, 0.2); }")
        else:
            L.append("    if (cz == 4) { r = (%s)(r + (%s)%s); }" % (T, T, three))
        M.append("(int)cq_measure(cz)")
        M.append("(int)cq_measure(r)")
    elif k == "printf":
        L.append("    printf(\"%d\\n\", (int)r);")
    elif k == "deadadd":
        # L3 p18 / `..._derived_base_add_late_use_frozen.ll`: a post-region user
        # keeps the merge phi alive while the chain itself is DEAD, so the
        # whole-DAG spine wants to reverse and free the rotated rail.
        L.append("    %s sd = (%s)(r + (%s)%s);" % (T, T, T, one))
        L.append("    (void)cq_theta(sd, 0.13);")
    elif k == "deadmul":
        L.append("    %s sd = (%s)(r * (%s)%s);" % (T, T, T, three))
        L.append("    (void)cq_theta(sd, 0.13);")
    elif k == "call":
        L.append("    (void)sinkfn((int)r);")
    elif k == "invert":
        L.append("    __cq_invert_begin(); r = cq_phi(r, 0.14); __cq_invert_end();")
        M.append("(int)cq_measure(r)")

    if ret is None:
        ret = " + ".join(M) if M else "0"

    src = ["#include <stdio.h>", "volatile int gsink;"]
    if c["cons"] == "call":
        src.append("__attribute__((noinline)) static int sinkfn(int x)"
                   " { return (int)cq_measure(x); }")
    src.append("%s slice(int cc) {" % rt)
    src += L
    src += extra
    src.append("    return %s;" % ret)
    src.append("}")
    src.append("int main(void){ (void)slice(1); return 0; }")
    return ("\n".join(src) + "\n").replace("ARM(", arm + "(")


# ─────────────────────────── TRACE MACHINERY ─────────────────────────────────

# THE Rz-SIDE REDUCER IS SHARED, NOT RE-SPELT (Rule 14). `--route-oracle` needs a
# reducer that collapses EVERY routed phase region — batched multi-arm allocs and
# all — into its `cqrt_rz_<W>_controlled` form, which is exactly what the Inc-2a
# golden audit already implements. Two spellings of one rewrite is how this
# project's predicates come to disagree (bd uow0 / 1fim), so import it.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import golden_multiset_audit as gma  # noqa: E402

CALL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\((.*?)\)(?: -> (.*))?$")
HANDLE = re.compile(r"\bh(\d+)\b")


def parse(line):
    m = CALL.match(line.strip())
    if not m:
        return None
    fn, args, ret = m.group(1), m.group(2), m.group(3)
    a = [x.strip() for x in args.split(",")] if args else []
    return fn, a, ret


def reduce_route(lines, arm_hex):
    """Collapse every ROUTE of a region-under-test to its in-place equivalent.

    Two shapes, both measured on this build:
      unbracketed (true arm)
        alloc_W(0)->R ; cswap(f,r,R) ; rz_W(R,t) ; cswap(f,r,R) ; free(R)
          ->  ry_W_controlled(f,r,t)
      bracketed (negated arm; the route brackets EACH cswap, the rz is bare,
      while the in-place path brackets the controlled gate itself)
        alloc_W(0)->R ; x(f);cswap(f,r,R);x(f) ; rz_W(R,t)
                      ; x(f);cswap(f,r,R);x(f) ; free(R)
          ->  x(f) ; ry_W_controlled(f,r,t) ; x(f)

    Only routes whose rz angle is in `arm_hex` are collapsed — a `route2`
    consumer's genuine phase region is left alone, on BOTH sides.
    Returns (reduced_lines, n_collapsed).
    """
    out, i, n = [], 0, 0
    P = [parse(l) for l in lines]
    while i < len(lines):
        p = P[i]
        if p and p[0].startswith("cqrt_alloc_") and p[1] in (["0"], ["0x0p+0"]) and p[2]:
            W = p[0][len("cqrt_alloc_"):]
            R = p[2]
            for width in (5, 9):
                if i + width > len(lines):
                    continue
                seg = P[i + 1:i + width]
                if any(s is None for s in seg):
                    continue
                if width == 5:
                    cs1, rz, cs2, fr = seg
                    xs = None
                else:
                    x1, cs1, x2, rz, x3, cs2, x4, fr = seg
                    if not all(s[0] == "cqrt_x" for s in (x1, x2, x3, x4)):
                        continue
                    if len({x1[1][0], x2[1][0], x3[1][0], x4[1][0]}) != 1:
                        continue
                    xs = x1[1][0]
                if cs1[0] != "cqrt_cswap" or cs2[0] != "cqrt_cswap":
                    continue
                if cs1[1] != cs2[1] or len(cs1[1]) != 3 or cs1[1][2] != R:
                    continue
                if rz[0] != "cqrt_rz_" + W or len(rz[1]) != 2 or rz[1][0] != R:
                    continue
                if rz[1][1] not in arm_hex:
                    continue
                if fr[0] != "cqrt_free" or fr[1] != [R]:
                    continue
                f, r = cs1[1][0], cs1[1][1]
                if xs is not None and xs != f:
                    continue
                if xs is not None:
                    out.append("cqrt_x(%s)" % f)
                out.append("cqrt_ry_%s_controlled(%s, %s, %s)"
                           % (W, f, r, rz[1][1]))
                if xs is not None:
                    out.append("cqrt_x(%s)" % f)
                i += width
                n += 1
                break
            else:
                out.append(lines[i]); i += 1
            continue
        out.append(lines[i]); i += 1
    return out, n


ZERO_ANGLE = ("0x0p+0", "-0x0p+0")


def reduce_prep(lines, seed_is):
    """Collapse the Increment-1 CHAINED TWIN's trace to the Increment-4 stream.

    Two rewrites, both PHYSICAL IDENTITIES of the trace algebra (see the
    `PREP_SEEDS` block for why that distinction is the whole point):

      (i)  DELETE  `cqrt_ry_<W>(h, 0x0p+0)`  — Ry(0) is the identity matrix, so
           removing it changes no state. The handle `h` is remembered.
      (ii) MOVE    `cqrt_alloc_<W>(SEED) -> h` to immediately before the FIRST
           `cqrt_ry_<W>_controlled(f, h, .)` that names `h` — a fresh-rail
           allocation acts on a wire no earlier gate mentions, so it commutes
           past all of them.

    ⚠ THE POSITION IN (ii) IS A CHOICE, AND IT IS THE ONE THE PRD'S EMISSION
    RECIPE MAKES. PRD §6 mints the flag AT the branch and then hoists the arm
    theta to BEFORE the branch, so `lowerRotations` mints the alloc at the
    hoisted theta — after the flag mint and, for a NEGATED arm, INSIDE the
    `cqrt_x` bracket. An implementation that hoists the alloc further up (also
    correct physics — the alloc commutes) produces a byte-different trace and
    this reducer will call it a MISMATCH. That is deliberate: the position has to
    be decided once and pinned, not discovered per golden.

    `seed_is` is the cell's `seed_matcher` — a NUMERIC predicate on the alloc's
    literal argument (see that function for why textual matching is a trap).
    Returns (reduced_lines, n_seeds_reduced).
    """
    out, seeded, n = [], [], 0
    for l in lines:
        q = parse(l)
        if (q and re.fullmatch(r"cqrt_ry_\w+", q[0]) and len(q[1]) == 2
                and q[1][1] in ZERO_ANGLE):
            seeded.append(q[1][0])
            continue
        out.append(l)
    for h in seeded:
        ai = None
        for i, l in enumerate(out):
            q = parse(l)
            if (q and q[0].startswith("cqrt_alloc_") and q[2] == h
                    and len(q[1]) == 1 and seed_is(q[1][0])):
                ai = i
                break
        if ai is None:
            continue                       # not a seeded prep rail — leave it
        alloc = out.pop(ai)
        ci = None
        for i, l in enumerate(out):
            q = parse(l)
            if (q and re.fullmatch(r"cqrt_ry_\w+_controlled", q[0])
                    and len(q[1]) == 3 and q[1][1] == h):
                ci = i
                break
        out.insert(len(out) if ci is None else ci, alloc)
        n += 1
    return out, n


def seed_matcher(c):
    """A predicate: does this `cqrt_alloc_<W>(<lit>)` argument spell the SEED?

    NUMERIC, never textual, and that is a measured decision rather than a
    stylistic one. Integer widths trace a decimal, fp widths trace C's `%a` — and
    C's `%a` and Python's `float.hex()` DISAGREE on exactly the seed this axis
    uses most: the runtime prints `cqrt_alloc_f64(0x0p+0)` while
    `(0.0).hex()` is `'0x0.0p+0'`. A textual set would silently fail to find the
    alloc, the reducer would return `n=0`, and every f64 cell would report
    MISMATCH for a harness reason. Comparing the VALUES cannot drift that way.
    """
    want = float(PREP_SEEDS[c["prep"]][c["width"]])

    def match(lit):
        try:
            return float.fromhex(lit) == want if lit.lower().startswith(
                ("0x", "-0x", "+0x")) else float(lit) == want
        except ValueError:
            return False

    return match


def classify_prep(nm, subj, twin, seed_is):
    """-> dict(verdict, notes[], inv[], pdiff)

    VERDICT VOCABULARY, and each name says which side moved:
      DECLINE-BOTH                  both refuse (the pre-Increment-4 state).
      DECLINE-BOTH-DIFF             both refuse with different diagnostics.
      SUBJECT-DECLINES-TWIN-ACCEPTS the EXPECTED pre-Increment-4 verdict for
                                    every in-scope cell: the chained reference
                                    lowers, the state-prep spelling does not.
      IDENTICAL                     both lower and the subject's trace equals the
                                    REDUCED twin's, byte for byte, handles
                                    renumbered by first appearance. This is the
                                    Increment-4 success verdict.
      MISMATCH                      both lower and the traces differ. A FINDING.
      SUBJECT-ACCEPTS-TWIN-DECLINES SUSPICIOUS: the new path took a shape the
                                    long-cleared chained path refuses.
      HARNESS-ERROR                 a stage failed; never a verdict about the
                                    compiler.
    """
    R = dict(verdict="", notes=[], inv=[], pdiff="", nred=0,
             subj_diag=subj.diag, twin_diag=twin.diag,
             subj_pair=subj.pair, subj_warn=subj.warn)
    if subj.error or twin.error:
        R["verdict"] = "HARNESS-ERROR"
        R["notes"].append((subj.error or "") + " | " + (twin.error or ""))
        return R
    if subj.exit != 0 and twin.exit != 0:
        R["verdict"] = ("DECLINE-BOTH" if subj.diag == twin.diag
                        else "DECLINE-BOTH-DIFF")
        return R
    if subj.exit != 0:
        R["verdict"] = "SUBJECT-DECLINES-TWIN-ACCEPTS"
        return R
    if twin.exit != 0:
        R["verdict"] = "SUBJECT-ACCEPTS-TWIN-DECLINES"
        R["inv"] += invariants(subj)
        return R

    red, nred = reduce_prep(twin.trace, seed_is)
    R["nred"] = nred
    if nred == 0:
        R["notes"].append("reducer found no seeded prep rail to collapse — the "
                          "twin's trace was compared UNREDUCED, so a MISMATCH "
                          "here is a harness fact, not a compiler one")
    a, b = normalise(subj.trace), normalise(red)
    if a == b:
        R["verdict"] = "IDENTICAL"
    else:
        R["verdict"] = "MISMATCH"
        i = next((k for k in range(max(len(a), len(b)))
                  if k >= len(a) or k >= len(b) or a[k] != b[k]), 0)
        R["pdiff"] = ("line %d:\n   subject       : %s\n   reduced twin  : %s"
                      % (i + 1,
                         a[i] if i < len(a) else "<end>",
                         b[i] if i < len(b) else "<end>"))
    R["inv"] += invariants(subj)
    return R


def normalise(lines):
    """Renumber handles by FIRST APPEARANCE. Mandatory: the Rz side mints one
    extra alloc per route, so every later number shifts by a constant that is
    not a defect. A real REORDERING still shows up."""
    m, out = {}, []
    for l in lines:
        def sub(x):
            k = x.group(1)
            if k not in m:
                m[k] = str(len(m))
            return "h" + m[k]
        out.append(HANDLE.sub(sub, l))
    return out


def flags_and_rails(lines):
    f, r = set(), set()
    for l in lines:
        p = parse(l)
        if p and re.fullmatch(r"cqrt_ry_\w+_controlled", p[0]) and len(p[1]) == 3:
            f.add(p[1][0]); r.add(p[1][1])
    return f, r


def prefix_end(lines):
    """Index (exclusive) of the last region-flag `cqrt_free`, or len(lines)."""
    f, _ = flags_and_rails(lines)
    if not f:
        return None
    last = None
    for i, l in enumerate(lines):
        p = parse(l)
        if p and p[0] == "cqrt_free" and len(p[1]) == 1 and p[1][0] in f:
            last = i
    return None if last is None else last + 1


# ─────────────────────────────── ONE SIDE ────────────────────────────────────

class Side:
    def __init__(self):
        self.exit = None
        self.diag = ""
        self.warn = ""
        self.nwarn = 0
        self.trace = None
        self.pair = ""
        self.error = None
        self.ll = None


def _first(text, tok):
    for line in text.splitlines():
        i = line.find(tok)
        if i >= 0:
            return line[i:].strip()
    return ""


def build(cfg, work, nm, src, cqopt=None):
    s = Side()
    cqopt = cqopt or cfg.cqopt
    cp = os.path.join(work, nm + ".c")
    open(cp, "w").write(src)
    s1 = os.path.join(work, nm + ".s1.ll")
    r = subprocess.run([cfg.clang, "-I", cfg.include, "-include", "CQ.h", "-O1",
                        "-emit-llvm", "-S", cp, "-o", s1],
                       capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "stage1: " + r.stderr.strip()[:400]
        return s
    s2 = os.path.join(work, nm + ".s2.ll")
    r = subprocess.run([cqopt, "-passes=cq-lowering", "-S", s1, "-o", s2],
                       capture_output=True, text=True)
    s.exit = r.returncode
    s.diag = _first(r.stderr, "cq ")
    s.warn = _first(r.stderr, "warning")
    s.nwarn = r.stderr.count("warning:")
    if r.returncode != 0:
        return s
    s.ll = open(s2).read()
    r = subprocess.run([sys.executable, cfg.pairchk, s2],
                       capture_output=True, text=True, cwd=cfg.root)
    s.pair = (r.stdout + r.stderr).strip()
    if r.returncode != 0:
        s.pair = "STAGE2B-FAIL: " + s.pair
    exe = os.path.join(work, nm + ".exe")
    # `__cq_invert_begin/_end` are bare externs with NO runtime definition
    # anywhere in the tree (Phase 8 is unimplemented and the pass leaves the
    # markers in place), so an `invert` cell links only against a local stub.
    # This is a HARNESS accommodation and changes nothing the compiler emitted —
    # see the report's NOTE on the pre-existing unlinkable-module behaviour.
    extra_objs = []
    if "__cq_invert_begin" in src:
        stub_c = os.path.join(work, "cqinvstub.c")
        stub_o = os.path.join(work, "cqinvstub.o")
        open(stub_c, "w").write("void __cq_invert_begin(void){}\n"
                                "void __cq_invert_end(void){}\n")
        subprocess.run([cfg.clang, "-c", stub_c, "-o", stub_o],
                       capture_output=True, text=True)
        extra_objs = [stub_o]
    if cfg.ld and os.access(cfg.ld, os.X_OK):
        obj = os.path.join(work, nm + ".o")
        r = subprocess.run([cfg.clang, "-c", s2, "-o", obj],
                           capture_output=True, text=True)
        if r.returncode == 0:
            r = subprocess.run([cfg.ld, "-o", exe, obj] + extra_objs +
                               [cfg.templates, cfg.runtime],
                               capture_output=True, text=True)
    else:
        r = subprocess.run([cfg.clang, s2] + extra_objs +
                           [cfg.templates, cfg.runtime, "-o", exe],
                           capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "link: " + r.stderr.strip()[:400]
        return s
    r = subprocess.run([exe], capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "run exited %d" % r.returncode
        return s
    s.trace = r.stdout.splitlines()
    return s


# ────────────────────────────── ONE CELL ─────────────────────────────────────

def run_cell(cfg, c):
    nm = name(c)
    work = cfg.keep and os.path.join(cfg.keep, nm) or tempfile.mkdtemp(prefix="cqip_")
    if cfg.keep:
        os.makedirs(work, exist_ok=True)
    if "prep" in c:
        # THE STATE-PREP AXIS (bd drbq Inc 4). Two sides, and the ORACLE side is
        # the one that moves: the SUBJECT is built with the build under test and
        # the TWIN with the PRE-Increment-4 binary, so an Increment-4 change to
        # the chained path cannot flatter its own witness.
        try:
            subj = build(cfg, work, nm + "_prep", gen(c, "prep"))
            twin = build(cfg, work, nm + "_twin", gen(c, "twin"),
                         cfg.prep_oracle or None)
        finally:
            if not cfg.keep:
                shutil.rmtree(work, ignore_errors=True)
        return nm, c, classify_prep(nm, subj, twin, seed_matcher(c))
    try:
        ry = build(cfg, work, nm + "_ry", gen(c, "cq_theta"))
        rz = build(cfg, work, nm + "_rz", gen(c, "cq_phi"))
        # THE ORACLE INVERSION (bd drbq Inc 2a, PRD §12.2(iii)). Before 2a the Rz
        # spelling ROUTED, so the same binary supplied both the subject and the
        # oracle. 2a lowers the Rz twin control-in-place too, so the routed oracle
        # now has to come from a PRE-2a binary — one built from `f92d95e` in a
        # scratch worktree. With `--route-oracle` set, `rzo` is that binary's Rz
        # trace and it is the ONLY route in the picture.
        rzo = (build(cfg, work, nm + "_rzo", gen(c, "cq_phi"), cfg.route_oracle)
               if cfg.route_oracle else None)
    finally:
        if not cfg.keep:
            shutil.rmtree(work, ignore_errors=True)
    return nm, c, classify(nm, ry, rz, rzo)


ARM_HEX = set(float(a).hex() for a in ARM_ANGLES)


def classify(nm, ry, rz, rzo=None):
    """-> dict(verdict, notes[], prefix_diff, suffix, inv[], rzv)

    `rzo` is the PRE-2a (routing) binary's Rz side, present only under
    `--route-oracle`. It supplies BOTH oracles: the Ry comparison below uses it
    instead of `rz` (which no longer routes), and `rzv` records the additional
    Rz-vs-collapsed-route verdict — full-trace, PREFIX AND SUFFIX, because the Rz
    stem is transparent to uncomputation (PRD §12.1) and therefore owes byte
    identity everywhere, not only up to the flag free.
    """
    R = dict(verdict="", notes=[], inv=[], suffix="", pdiff="", rzv="",
             ry_diag=ry.diag, rz_diag=rz.diag, ry_warn=ry.warn,
             ry_pair=ry.pair, rz_pair=rz.pair)
    if rzo is not None:
        R["rzv"] = classify_rz(rz, rzo, R)
    # The ROUTED oracle is `rzo` when one was supplied; `rz` otherwise (the
    # pre-2a behaviour, kept so the script still runs against an old build).
    oracle = rzo if rzo is not None else rz
    if ry.error or oracle.error:
        R["verdict"] = "HARNESS-ERROR"
        R["notes"].append((ry.error or "") + " | " + (oracle.error or ""))
        return R
    if ry.exit != 0 and oracle.exit != 0:
        R["verdict"] = ("DECLINE-BOTH" if ry.diag == oracle.diag
                        else "DECLINE-BOTH-DIFF")
        return R
    if ry.exit != 0:
        R["verdict"] = "RZ-ONLY(over-decline)"
        return R
    if oracle.exit != 0:
        R["verdict"] = "RY-ONLY(suspicious)"
        # still check the Ry-side invariants
        R["inv"] += invariants(ry)
        return R

    # both accept
    red, ncoll = reduce_route(oracle.trace, ARM_HEX)
    ryn, rzn = normalise(ry.trace), normalise(red)
    ncry = len(re.findall(r"cqrt_ry_\w+_controlled\(", "\n".join(ry.trace)))
    if ncry == 0:
        R["verdict"] = "ACCEPT-NO-CRY"
        R["notes"].append("no cqrt_ry_*_controlled on the Ry side "
                          "(%d route(s) collapsed on the Rz side)" % ncoll)
        if ry.trace == oracle.trace:
            R["notes"].append("traces identical")
        R["inv"] += invariants(ry)
        return R
    if ncry != ncoll:
        R["inv"].append("I1 controlled-Ry count %d != collapsed routes %d"
                        % (ncry, ncoll))

    pe_ry, pe_rz = prefix_end(ryn), prefix_end(rzn)
    if pe_ry is None or pe_rz is None:
        R["verdict"] = "PREFIX-UNBOUNDED"
        pe_ry = pe_ry or len(ryn)
        pe_rz = pe_rz or len(rzn)
    pry, prz = ryn[:pe_ry], rzn[:pe_rz]
    sry, srz = ryn[pe_ry:], rzn[pe_rz:]

    if pry == prz:
        R["verdict"] = R["verdict"] or "PREFIX-IDENTICAL"
    else:
        R["verdict"] = "PREFIX-MISMATCH"
        i = next((k for k in range(max(len(pry), len(prz)))
                  if k >= len(pry) or k >= len(prz) or pry[k] != prz[k]), 0)
        R["pdiff"] = ("line %d:\n   ry: %s\n   rz: %s"
                      % (i + 1,
                         pry[i] if i < len(pry) else "<end>",
                         prz[i] if i < len(prz) else "<end>"))

    if sry == srz:
        R["suffix"] = "SUFFIX-IDENTICAL"
    elif not sry and srz:
        R["suffix"] = "SUFFIX-RZ-EXTRA(%d)" % len(srz)
    elif sry and not srz:
        R["suffix"] = "SUFFIX-RY-EXTRA(%d)" % len(sry)
    else:
        # is ry's suffix a subsequence-prefix of rz's? classify the shape
        common = os.path.commonprefix([sry, srz])
        if len(common) == len(sry) and len(srz) > len(sry):
            R["suffix"] = "SUFFIX-RZ-LONGER(+%d)" % (len(srz) - len(sry))
        elif len(common) == len(srz) and len(sry) > len(srz):
            R["suffix"] = "SUFFIX-RY-LONGER(+%d)" % (len(sry) - len(srz))
        else:
            # ⚠ ONE DIVERGENCE SHAPE IS AN INSTRUMENT ARTIFACT SINCE bd drbq Inc 2a,
            # AND IT MUST NOT BE REPORTED AS A FINDING. `reduce_route` above
            # deliberately reduces ONLY routes whose arm angle is in `ARM_HEX`, so
            # that a route belonging to the REGION UNDER TEST can be told apart
            # from one belonging to a `route2` consumer — a second, genuine phase
            # region that was a route in BOTH spellings. That discrimination is
            # what makes the I1 invariant (`controlled-Ry count == collapsed
            # routes`) mean anything, so it stays.
            #
            # But Inc 2a collapses EVERY flat phase region, `route2` included, on
            # the build under test — while the pre-2a oracle still routes it and
            # `reduce_route` deliberately leaves it alone. The suffixes then
            # diverge for a reason that is the increment working, not failing. So:
            # re-reduce the OLD suffix with the FULL reduction (the one the Inc-2a
            # golden audit uses, which reduces every routed region regardless of
            # angle) and, if the two then agree, say so in its own label.
            #
            # This is a NARROWING of the report, never of the check: the label is
            # only reachable when the two suffixes become byte-identical after the
            # old one is reduced, i.e. when the ONLY difference was a collapsed
            # route. Anything else still reports `SUFFIX-DIVERGENT`.
            if normalise(gma.reduce_routes(srz)[0]) == normalise(sry):
                R["suffix"] = "SUFFIX-2A-COLLAPSE(expected)"
            else:
                k = len(common)
                R["suffix"] = ("SUFFIX-DIVERGENT@%d ry=%r rz=%r"
                               % (k + 1,
                                  sry[k] if k < len(sry) else "<end>",
                                  srz[k] if k < len(srz) else "<end>"))
    R["inv"] += invariants(ry)
    if ry.nwarn != oracle.nwarn:
        R["notes"].append("warnings ry=%d rz=%d: %s"
                          % (ry.nwarn, oracle.nwarn, ry.warn or oracle.warn))
    return R


def classify_rz(rz, rzo, R):
    """The Rz-STEM verdict under `--route-oracle` (bd drbq Inc 2a, PRD §12.2(iii)).

    `rzo` is the PRE-2a binary's trace, in which the same source still ROUTES;
    `rz` is this build's, in which the flat phase region lowers control-in-place.
    The claim under test is stronger than the Ry side's: for the Rz stem the whole
    trace must match, PREFIX AND SUFFIX, because the controlled Rz is DIAGONAL and
    therefore transparent to uncomputation — it is NOT a DAG link, is never
    adjointed, and does NOT freeze its register (PRD §12.1), so every post-region
    `_unc`, `cqrt_free` and adjoint must be exactly what the route produced. A
    SUFFIX difference here is a FINDING, not a scope fact — which is precisely the
    axis the Ry side cannot police, because the Ry freeze legitimately truncates
    its own suffix.

    The reduction is `golden_multiset_audit.reduce_routes` — the same rewrite the
    golden audit applies, shared rather than re-spelt (Rule 14).
    """
    if rz.error or rzo.error:
        return "RZ-HARNESS-ERROR"
    if rz.exit != rzo.exit:
        R["notes"].append("rz disposition moved: pre-2a exit %s, now %s (%s)"
                          % (rzo.exit, rz.exit, rz.diag or rzo.diag))
        return "RZ-DISPOSITION-MOVED"
    if rz.exit != 0:
        return "RZ-DECLINE-BOTH" if rz.diag == rzo.diag else "RZ-DECLINE-DIFF"
    # bd drbq Inc 3, 2026-09-04 — PRE-EXISTING ARITY BUG, fixed here so the
    # instrument can run at all. `golden_multiset_audit.reduce_routes` returns
    # FIVE values (it gained `n_negated_arms` at 24bb42d, the same commit that
    # last touched this file) and this line unpacked FOUR, so EVERY `--route-oracle`
    # run died with `ValueError: too many values to unpack (expected 4)` before
    # classifying one cell. Verified pre-existing: `git diff 1bdaa60 -- tools/`
    # is empty for both files. The sibling call at :795 already uses `[0]` and was
    # never affected, which is why nothing else noticed.
    red, nreg, _narm, _ng, _nneg = gma.reduce_routes(rzo.trace)
    a, b = normalise(red), normalise(rz.trace)
    if a == b:
        return "RZ-COLLAPSE-ONLY(%d)" % nreg
    i = next((k for k in range(max(len(a), len(b)))
              if k >= len(a) or k >= len(b) or a[k] != b[k]), 0)
    R["notes"].append("RZ mismatch at line %d:\n         collapsed-route: %s"
                      "\n         in-place       : %s"
                      % (i + 1,
                         a[i] if i < len(a) else "<end>",
                         b[i] if i < len(b) else "<end>"))
    return "RZ-MISMATCH"


def invariants(ry):
    bad = []
    tr = ry.trace or []
    flags, rails = flags_and_rails(tr)
    # I2 — an adjoint controlled rotation. Every angle this generator emits is
    # POSITIVE, so a negative one can only have been synthesized by EmitInverse.
    for l in tr:
        p = parse(l)
        if p and re.fullmatch(r"cqrt_r[yz]_\w+_controlled", p[0]):
            if p[1][-1].startswith("-"):
                bad.append("I2 negated controlled rotation: " + l)
    # I3 — no free of a rotated rail (the freeze)
    for l in tr:
        p = parse(l)
        if p and p[0] == "cqrt_free" and p[1] and p[1][0] in rails:
            bad.append("I3 cqrt_free of a rotated rail: " + l)
    # I4 — each flag free preceded by an `_unc` naming it
    for f in flags:
        seen_unc = False
        for l in tr:
            p = parse(l)
            if not p:
                continue
            if p[0].endswith("_unc") and p[1] and p[1][0] == f:
                seen_unc = True
            if p[0] == "cqrt_free" and p[1] == [f]:
                if not seen_unc:
                    bad.append("I4 cqrt_free(%s) with no preceding _unc(%s,...)"
                               % (f, f))
                break
    # I6 — THE ROUND-1 L3 SIGNATURE, GENERALIZED. The freeze protects the
    # ROTATED rail from being reversed; it must also stop any OTHER rail's
    # adjoint from reading it. An `X_unc(d, ops...)` reverses the rail `d` that
    # `X(ops...) -> d` produced; if that FORWARD ran BEFORE the controlled Ry
    # relabelled a rail in `ops`, the adjoint is reversing against a basis the
    # register no longer holds — the use-after-free + dirty free of round 1, one
    # rail out. (An adjoint whose forward is AFTER the rotation reads the same,
    # post-Ry basis and is sound.)
    #
    # THE PAIRING IS BY (name, trailing args, produced rail), NOT BY NAME. A
    # first draft matched on the callee name alone and reported three FALSE
    # POSITIVES on `add`-base x f64 x spine cells, where `double r = p + 5.0`
    # and `double s = r + 1.0` are BOTH `cq_template_fadd_f64_hl` and the
    # earlier one straddles the gate. Measured, then fixed here.
    first_cry = {}
    for i, l in enumerate(tr):
        p = parse(l)
        if p and re.fullmatch(r"cqrt_ry_\w+_controlled", p[0]) and len(p[1]) == 3:
            first_cry.setdefault(p[1][1], i)
    if first_cry:
        fwd = {}                       # (name, tuple(args), ret) -> first index
        for i, l in enumerate(tr):
            p = parse(l)
            if p and p[2] and not p[0].endswith("_unc"):
                fwd.setdefault((p[0], tuple(p[1]), p[2]), i)
        for j, l in enumerate(tr):
            p = parse(l)
            if not p or not p[0].endswith("_unc") or len(p[1]) < 2:
                continue
            key = (p[0][:-4], tuple(p[1][1:]), p[1][0])
            i = fwd.get(key)
            if i is None:
                continue               # not a template out-of-place pair
            for R, ci in first_cry.items():
                # `R` may be the rail BEING REVERSED (the round-1 L3 shape, where
                # the frozen register itself was reversed) or an OPERAND the
                # adjoint reads (the same defect one rail out) — both are
                # "a gate relabelled it between the forward and the adjoint".
                if R in p[1] and i < ci < j:
                    bad.append("I6 %s reverses rail %s against %s, which the "
                               "controlled Ry relabelled between the forward "
                               "(line %d) and the adjoint (line %d; cRy at %d)"
                               % (p[0], p[1][0], R, i + 1, j + 1, ci + 1))
    # I5 — strict stage 2b
    if "violation" in ry.pair:
        m = re.search(r"(\d+) violation\(s\), (\d+) unproven", ry.pair)
        if m and (m.group(1) != "0" or m.group(2) != "0"):
            bad.append("I5 stage2b: " + ry.pair.splitlines()[-1])
    if ry.pair.startswith("STAGE2B-FAIL"):
        bad.append("I5 " + ry.pair.splitlines()[0])
    return bad


# ──────────────────────────────── DRIVER ─────────────────────────────────────

def _star(a):
    return run_cell(*a)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--llvm", default="/usr/local/opt/llvm@19/bin")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--only", default="")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--keep", default="")
    ap.add_argument("--out", default="")
    ap.add_argument("--triples", action="store_true",
                    help="run the hand-picked 3-way slice instead of all-pairs")
    ap.add_argument("--quick", action="store_true",
                    help="a <1min smoke subset (NOT a green matrix)")
    ap.add_argument("--stateprep", action="store_true",
                    help="run the bd drbq Increment-4 CONTROLLED STATE-PREP pool "
                         "(`sp_*` cells) INSTEAD of the five-axis pool. Its "
                         "oracle is --prep-oracle (a PRE-Increment-4 `cq-opt`), "
                         "not --route-oracle. Combine with --only to run a slice.")
    ap.add_argument("--prep-oracle", default="",
                    help="path to a PRE-Increment-4 `cq-opt` (built from "
                         "`b506b3b`), used to build the CHAINED TWIN of every "
                         "`--stateprep` cell. Falls back to --route-oracle when "
                         "only that is given; falls back to the build under test "
                         "with a loud warning when neither is, in which case the "
                         "run proves nothing about Increment 4.")
    ap.add_argument("--route-oracle", default="",
                    help="path to a PRE-2a `cq-opt` (built from f92d95e) whose Rz "
                         "spelling still ROUTES. With it the oracle INVERTS: the "
                         "routed stream comes from that binary, this build's Ry "
                         "side is compared to it on the PREFIX as before, and this "
                         "build's Rz side is additionally compared to it on the "
                         "WHOLE trace (prefix AND suffix — the Rz stem is "
                         "transparent to uncomputation, PRD §12.1)")
    cfg = ap.parse_args()
    if cfg.route_oracle and not os.access(cfg.route_oracle, os.X_OK):
        sys.stderr.write("route-oracle not executable: %s\n" % cfg.route_oracle)
        return 2
    if not cfg.prep_oracle:
        cfg.prep_oracle = cfg.route_oracle
    if cfg.prep_oracle and not os.access(cfg.prep_oracle, os.X_OK):
        sys.stderr.write("prep-oracle not executable: %s\n" % cfg.prep_oracle)
        return 2
    if cfg.stateprep and not cfg.prep_oracle:
        sys.stderr.write(
            "\n⚠ --stateprep WITHOUT --prep-oracle: the CHAINED TWIN is being "
            "built with\n  the same binary as the subject, so this run cannot "
            "distinguish an Increment-4\n  change to the state-prep path from an "
            "Increment-4 change to the chained path.\n  Build the PRE-Increment-4 "
            "oracle and pass it. See the PREP_SEEDS block.\n\n")
    cfg.clang = os.path.join(cfg.llvm, "clang")
    cfg.cqopt = os.path.join(cfg.root, "build/ir-pass/cq-opt")
    cfg.include = os.path.join(cfg.root, "include")
    cfg.pairchk = os.path.join(cfg.root, "tools/free_pairing_check.py")
    cfg.templates = os.path.join(cfg.root, "build/runtime/libcq_templates.a")
    cfg.runtime = os.path.join(cfg.root, "build/runtime/libcq_runtime.a")
    cfg.ld = os.environ.get("CQ_LD",
                            os.path.join(cfg.root, "build/tests/e2e/cq_link.sh"))

    pool = (prep_cells() if cfg.stateprep
            else quick_cells() if cfg.quick
            else triple_cells() if cfg.triples
            else cells())
    cs = [c for c in pool if not cfg.only or cfg.only in name(c)]
    if cfg.list:
        for c in cs:
            print(name(c))
        print("%d cells" % len(cs))
        return 0
    if cfg.keep:
        os.makedirs(cfg.keep, exist_ok=True)

    res = []
    with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
        for r in ex.map(_star, [(cfg, c) for c in cs]):
            res.append(r)
            sys.stderr.write(".")
            sys.stderr.flush()
    sys.stderr.write("\n")

    lines = []
    tally = {}
    rztally = {}
    for nm, c, R in sorted(res):
        tally[R["verdict"]] = tally.get(R["verdict"], 0) + 1
        flag = "!!" if (R["verdict"] in ("PREFIX-MISMATCH", "HARNESS-ERROR",
                                         "RY-ONLY(suspicious)", "MISMATCH",
                                         "SUBJECT-ACCEPTS-TWIN-DECLINES")
                        or R["inv"]
                        or R.get("suffix", "").startswith("SUFFIX-DIVERGENT")
                        or R.get("suffix", "").startswith("SUFFIX-RY")) else "  "
        if R.get("rzv"):
            rztally[R["rzv"].split("(")[0]] = \
                rztally.get(R["rzv"].split("(")[0], 0) + 1
            if R["rzv"].split("(")[0] in ("RZ-MISMATCH", "RZ-HARNESS-ERROR",
                                          "RZ-DISPOSITION-MOVED",
                                          "RZ-DECLINE-DIFF"):
                flag = "!!"
        lines.append("%s %-58s %-24s %-28s %-24s %s"
                     % (flag, nm, R["verdict"], R.get("suffix", ""),
                        # the reduction count is meaningful only when both
                        # sides lowered and the traces were actually compared.
                        R.get("rzv", "") or (
                            ("reduced %d" % R["nred"])
                            if R["verdict"] in ("IDENTICAL", "MISMATCH") else ""),
                        R.get("ry_diag") or R.get("rz_diag")
                        or R.get("subj_diag") or R.get("twin_diag") or ""))
        for n in R["notes"]:
            lines.append("      note: " + n)
        for iv in R["inv"]:
            lines.append("      INV : " + iv)
        if R.get("pdiff"):
            for l in R["pdiff"].splitlines():
                lines.append("      " + l)
    out = "\n".join(lines)
    print(out)
    mode = ("STATE-PREP" if cfg.stateprep else "QUICK" if cfg.quick
            else "TRIPLES" if cfg.triples else "ALL-PAIRS")
    print("\n=== TALLY (%s, %d cells) ===" % (mode, len(res)))
    for k in sorted(tally):
        print("  %-26s %d" % (k, tally[k]))
    if rztally:
        print("\n=== Rz STEM vs the INVERTED (pre-2a) ROUTE ORACLE, whole trace ===")
        for k in sorted(rztally):
            print("  %-26s %d" % (k, rztally[k]))
    if cfg.out:
        open(cfg.out, "w").write(out + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
