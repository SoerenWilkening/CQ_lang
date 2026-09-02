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
     closure marks NotClosed is left allocated; the Rz twin may reverse+free).
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
    return "c_%s_%s_%s_%s_%s" % (c["base"], c["cond"], c["cfg"], c["cons"],
                                 c["width"])


# ────────────────────────── THE C GENERATOR ──────────────────────────────────
# `ARM(` is the substitution point: cq_theta on the Ry side, cq_phi on the Rz
# side. NOTHING ELSE in the program changes between the two sides.

def gen(c, arm):
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
    b = c["base"]
    if b == "src":
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
        L.append("    if (%s) { r = ARM(r, 0.9); } else { r = ARM(r, 0.4); }"
                 % cexpr)
    elif c["cfg"] == "ifelse2":
        L.append("    %s r2 = (%s)%s; r2 = cq_theta(r2, 0.11);" % (T, T, nine))
        L.append("    if (%s) { r = ARM(r, 0.9); } else { r2 = ARM(r2, 0.4); }"
                 % cexpr)
        extra.append("    (void)cq_measure(r2);")
    else:
        L.append("    if (%s) { r = ARM(r, 0.9); }" % cexpr)

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


def build(cfg, work, nm, src):
    s = Side()
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
    r = subprocess.run([cfg.cqopt, "-passes=cq-lowering", "-S", s1, "-o", s2],
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
    try:
        ry = build(cfg, work, nm + "_ry", gen(c, "cq_theta"))
        rz = build(cfg, work, nm + "_rz", gen(c, "cq_phi"))
    finally:
        if not cfg.keep:
            shutil.rmtree(work, ignore_errors=True)
    return nm, c, classify(nm, ry, rz)


ARM_HEX = set(float(a).hex() for a in ARM_ANGLES)


def classify(nm, ry, rz):
    """-> dict(verdict, notes[], prefix_diff, suffix, inv[])"""
    R = dict(verdict="", notes=[], inv=[], suffix="", pdiff="",
             ry_diag=ry.diag, rz_diag=rz.diag, ry_warn=ry.warn,
             ry_pair=ry.pair, rz_pair=rz.pair)
    if ry.error or rz.error:
        R["verdict"] = "HARNESS-ERROR"
        R["notes"].append((ry.error or "") + " | " + (rz.error or ""))
        return R
    if ry.exit != 0 and rz.exit != 0:
        R["verdict"] = ("DECLINE-BOTH" if ry.diag == rz.diag
                        else "DECLINE-BOTH-DIFF")
        return R
    if ry.exit != 0:
        R["verdict"] = "RZ-ONLY(over-decline)"
        return R
    if rz.exit != 0:
        R["verdict"] = "RY-ONLY(suspicious)"
        # still check the Ry-side invariants
        R["inv"] += invariants(ry)
        return R

    # both accept
    red, ncoll = reduce_route(rz.trace, ARM_HEX)
    ryn, rzn = normalise(ry.trace), normalise(red)
    ncry = len(re.findall(r"cqrt_ry_\w+_controlled\(", "\n".join(ry.trace)))
    if ncry == 0:
        R["verdict"] = "ACCEPT-NO-CRY"
        R["notes"].append("no cqrt_ry_*_controlled on the Ry side "
                          "(%d route(s) collapsed on the Rz side)" % ncoll)
        if ry.trace == rz.trace:
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
            k = len(common)
            R["suffix"] = ("SUFFIX-DIVERGENT@%d ry=%r rz=%r"
                           % (k + 1,
                              sry[k] if k < len(sry) else "<end>",
                              srz[k] if k < len(srz) else "<end>"))
    R["inv"] += invariants(ry)
    if ry.nwarn != rz.nwarn:
        R["notes"].append("warnings ry=%d rz=%d: %s"
                          % (ry.nwarn, rz.nwarn, ry.warn or rz.warn))
    return R


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
    cfg = ap.parse_args()
    cfg.clang = os.path.join(cfg.llvm, "clang")
    cfg.cqopt = os.path.join(cfg.root, "build/ir-pass/cq-opt")
    cfg.include = os.path.join(cfg.root, "include")
    cfg.pairchk = os.path.join(cfg.root, "tools/free_pairing_check.py")
    cfg.templates = os.path.join(cfg.root, "build/runtime/libcq_templates.a")
    cfg.runtime = os.path.join(cfg.root, "build/runtime/libcq_runtime.a")
    cfg.ld = os.environ.get("CQ_LD",
                            os.path.join(cfg.root, "build/tests/e2e/cq_link.sh"))

    pool = (quick_cells() if cfg.quick
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
    for nm, c, R in sorted(res):
        tally[R["verdict"]] = tally.get(R["verdict"], 0) + 1
        flag = "!!" if (R["verdict"] in ("PREFIX-MISMATCH", "HARNESS-ERROR",
                                         "RY-ONLY(suspicious)")
                        or R["inv"]
                        or R["suffix"].startswith("SUFFIX-DIVERGENT")
                        or R["suffix"].startswith("SUFFIX-RY")) else "  "
        lines.append("%s %-58s %-24s %-28s %s"
                     % (flag, nm, R["verdict"], R["suffix"],
                        R["ry_diag"] or R["rz_diag"]))
        for n in R["notes"]:
            lines.append("      note: " + n)
        for iv in R["inv"]:
            lines.append("      INV : " + iv)
        if R["pdiff"]:
            for l in R["pdiff"].splitlines():
                lines.append("      " + l)
    out = "\n".join(lines)
    print(out)
    mode = "QUICK" if cfg.quick else "TRIPLES" if cfg.triples else "ALL-PAIRS"
    print("\n=== TALLY (%s, %d cells) ===" % (mode, len(res)))
    for k in sorted(tally):
        print("  %-26s %d" % (k, tally[k]))
    if cfg.out:
        open(cfg.out, "w").write(out + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
