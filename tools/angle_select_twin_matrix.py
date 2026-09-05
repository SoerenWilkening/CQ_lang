#!/usr/bin/env python3
"""angle_select_twin_matrix.py — the ANGLE-SELECT-EQUALS-BY-DIFFERENCE witness.

bd `test_C_libtooling-drbq` Increment 2b (angle-select by difference, both
rotation stems). Committed as an INSTRUMENT, not as a ctest gate — an owner cost
decision is pending (bd `drbq.9`), the same status
`tools/inplace_twin_matrix.py` and `tools/control_flag_order_check.py` have.
Read "WHAT IT CANNOT WITNESS" before quoting any number from it.

═══════════════════════════════════════════════════════════════════════════════
WHY THIS EXISTS

Increment 2b's correctness claim is one sentence: for

    if (c) r = R(r, A); else r = R(r, B);        <- what the user writes

`clang -O1` produces ONE call with an angle `select`, and the compiler lowers it
so that the emitted gate stream is byte-for-byte the stream of

    r = R(r, B); if (c) r = R(r, A - B);         <- the MANUAL by-difference form

which is an ordinary in-place rotation DIAMOND that the PRE-2b compiler already
lowered. CQ has no simulator (Rule 2, owner decision 2026-06-10), so that
byte-level twin identity is the strongest witness available — the same argument
`tools/loop_twin_matrix.py` makes for the rolled loop and
`tools/inplace_twin_matrix.py` makes for the route collapse.

The twin is a genuine ORACLE rather than a second copy of the subject BECAUSE it
is run on the pre-2b binary too: `--oracle <cq-opt>`. If the twin's own trace
ever moves between the two binaries, this instrument says so (`ORACLE-MOVED`)
and every other verdict in that cell is void.

═══════════════════════════════════════════════════════════════════════════════
WHAT ONE CELL IS

One C program in TWO spellings that differ only in how the two angles are
written, run through the FULL pipeline (clang -O1 -> cq-opt -> STRICT stage 2b
-> link -> run) on BOTH binaries — four pipelines per cell:

    select@new   the if/else form, on the build under test   (the subject)
    select@old   the if/else form, on the pre-2b oracle      (must DECLINE)
    twin@new     the by-difference form, on the build        (the oracle)
    twin@old     the by-difference form, on the pre-2b build (the oracle's own
                 oracle — it must not move)

FIVE AXES, all-pairs (the union of every 2-D plane through a default cell). That
design is not decoration: BOTH of this epic's round-1 confirmed silent
miscompiles were CROSSED-AXIS shapes — a DERIVED base x a post-region consumer,
and a CLASSICAL join phi x a non-`lowerOps` sink — each of which had a green
fixture on either axis alone.

    stem     theta | phi                    (Ry, the mechanism; Rz, the peephole)
    cond     eq | ne | sgt | slt | fcmp     (fcmp puts the condition on a
                                             SEPARATE double rail)
    base     src | chain | mul | add | phialias
    use      none | meas | ret | derived | region2 | premark | postmark
    angle    consts | args | equal | negative | zero

═══════════════════════════════════════════════════════════════════════════════
THE VERDICTS

    BOTH-ACCEPT-IDENTICAL  select@new == twin@new == twin@old, byte for byte.
                           The result the increment claims.
    OVER-DECLINE           the select form declines, the twin lowers. A SCOPE
                           fact, not a bug (Prime Directive) — the string is
                           printed so the scope is legible.
    SUSPICIOUS             the select form lowers and the twin does NOT. The
                           dangerous direction: the new path took a shape the
                           trusted one refused. Every one must be explained.
    MISMATCH               both lower and the traces differ. A finding.
    ORACLE-MOVED           twin@new != twin@old. A regression OUTSIDE this
                           increment; every other verdict in the cell is void.
    RED-GREEN-MISS         select@old ACCEPTED. The shape was not new, so the
                           cell proves nothing about the increment.
    BOTH-DECLINE           both refuse. The two diagnostics are printed; a
                           DIFFERENT pair of strings is worth a look but is not
                           a defect.
    DEGENERATE-FOLD        `clang -O1` left no `select` at all (the `equal`
                           angle axis folds `c ? x : x` away). Reported, not
                           compared — there is nothing under test in that cell.
    EXPECTED-DECLINE-RUNTIME-ARMS
                           the `angle=args` axis only: the select form declines
                           `rotation angle`, BY DESIGN. The Rule-13 CLEARANCE
                           review (bd `test_C_libtooling-drbq`, finding F-11)
                           narrowed the accept class to CONSTANT arms (owner
                           option (2)), so a run-time arm is refused. This is
                           the same disposition an OVER-DECLINE would report and
                           is split out from it so that a REAL scope surprise
                           stays visible: OVER-DECLINE now means an unexplained
                           one. The twin's disposition is printed in the note,
                           and it must not be read as an oracle here — see the
                           `args` bullet under WHAT IT CANNOT WITNESS.
    HARNESS-ERROR          a stage failed for a reason that is not a decline.

Every accepting cell additionally owes STRICT stage 2b
(`free_pairing_check.py`: 0 violations, 0 unproven) — a `STAGE2B` note is
printed for any cell that fails it, on either spelling.

═══════════════════════════════════════════════════════════════════════════════
WHAT IT CANNOT WITNESS — quote this with every result

  * IT HAS NO ORACLE FOR THE UNITARY. The twin is the SAME by-difference
    identity the compiler applies, written by hand. If `R(A) = R(B).R(A-B)` were
    false for this project's rotation convention, both sides would be wrong
    together and every cell would be green. That identity is argued analytically
    (`AngleSelectEmit.h`), not measured here.
  * THE TWIN IS EXEMPT FROM NOTHING THE SUBJECT IS EXEMPT FROM, but it IS a
    different detection path (a `br` diamond, not a select). A shape that the
    diamond path declines for its OWN reasons shows up as `SUSPICIOUS` even when
    the select form is right — every such cell is reproduced standalone before
    it is ranked.
  * THE TRACE LOSES RAIL IDENTITIES. `free_pairing_check.py` (stage 2b) is what
    sees those, and it is run per cell — but it is deliberately transparent to
    `cqrt_rz*` (diagonal), so the `phi` stem's rail bookkeeping is witnessed by
    the trace and the lit fixtures, not here.
  * IT CANNOT WITNESS IEEE ROUNDING, AND THAT IS STRUCTURAL, NOT AN OVERSIGHT
    (round-1 Rule-13 review, lens L7-F1/F5). The emitted true-arm angle is
    `B + fl(A-B)`, not `A`: the error is `|delta| <= 1/2 ulp(A-B)`, which is
    2^-54 rad on the `consts` pair and 0.858 rad on `pi / 1e16`. This instrument
    is blind to ALL of it, because THE TWIN IS ITSELF BY DIFFERENCE — it writes
    `R(r, B); if (c) R(r, A - B);` and `clang` folds the very same `A - B` with
    the very same rounding, so both sides carry the IDENTICAL delta and the diff
    is exact. Every constant cell here is `0.9/0.3`, `0.9/0.9`, `0.3/0.9` or
    `0.9/0.0`, whose deltas are 2^-54 or exactly 0; and the RUNTIME pair the
    `args` cells pass (`1.25`, `0.75`) is STERBENZ-EXACT (`fl(1.25-0.75) = 0.5`
    with no rounding at all), so not one cell in this table can exhibit the
    error even in principle. The fence for it lives in `ArmClassify`
    (`angleSelectArmsAdmissible`, `kAngleSelectMaxRoundingRad`) and its evidence
    is the lit pair `control_angle_select_{reject_rounding_pi_1e16,
    accept_rounding_flagship_bound}.ll`, with the THRESHOLD itself pinned by
    `control_angle_select_{accept_rounding_at_bound,reject_rounding_above_bound}.ll`
    (round-2 review). THE CELLS ARE DELIBERATELY LEFT AS THEY
    ARE — changing them would break the table's continuity with the authoring
    run for no gain, since a by-difference twin can never be an oracle for the
    rounding of a by-difference lowering.
  * AND IT IS BLIND TO THE OTHER HALF OF THE SAME RESIDUAL, WHICH IS NOT A
    ROUNDING AT ALL (round-2 Rule-13 review, lens R1 item 1). `fl(A-B)` can be
    `inf` or `NaN` from two perfectly ORDINARY FINITE arms — measured from plain
    C, `A = 8.98846567431158e307` and `B = -A` as `double` PARAMETERS emit
    `cqrt_ry_i32_controlled(f, h, inf)` where the source named a finite angle.
    The twin performs the identical `fsub` and manufactures the identical
    infinity, so the diff is again exact.
  * THE `args` CELLS NOW DECLINE ON THE SELECT SIDE, AND THAT IS THE POINT OF
    KEEPING THEM (Rule-13 CLEARANCE review, finding F-11; orchestrator decision:
    owner option (2), the accept class is CONSTANT ARMS ONLY). Both residual
    halves above are therefore no longer in the shipped accept class at all —
    they are the REASON run-time arms are refused. The 16 `angle=args` cells
    report EXPECTED-DECLINE-RUNTIME-ARMS and are the red-green witness for that
    refusal.
    ⚠ THEIR TWIN STILL ACCEPTS, AND IT IS NOT AN ORACLE. This harness passes the
    difference into the twin as a PARAMETER (`d` / `nd` from `main`, see the
    comment in `gen`), so the twin performs NO SUBTRACTION — it is not the
    program a user would write. The natural manual twin, which writes `A - B`
    itself, DECLINES `control flow` on BOTH binaries, because `clang -O1` sinks
    the `fsub` into the arm block and `inPlaceRotationArmTheta` refuses a stray
    op there (clearance observation 1, measured five ways). So there is no
    compilable twin oracle for the run-time-arm class anywhere, and an accepting
    `args` twin must never be quoted as "the select form is over-declining".
    Widening back is owner option (1), one line at `angleSelectArmsAdmissible`
    clause (2c) — see the three-way owner-desk item in
    `CONTROL_IN_PLACE_INC2B_NOTES.md` §9 and the clearance record in §11.
  * A GREEN MATRIX IS NOT A CLEARED INCREMENT (Rule 13). It is one lens.

═══════════════════════════════════════════════════════════════════════════════
HOW TO RUN IT, AND WHAT IT COSTS

    python3 tools/angle_select_twin_matrix.py --jobs 8 \
            --oracle /path/to/pre-2b/build/ir-pass/cq-opt

    --list      print the cell names and exit
    --quick     a smoke subset (NOT a green matrix)
    --only STR  substring filter on the cell name
    --keep DIR  keep the generated .c/.ll/.exe per cell
    --out FILE  also write the table to FILE

MEASURED, all-pairs, `--jobs 8`, oracle supplied: **158 cells = 632 full
pipelines, 165-250 s wall** across five runs on a box that was not always quiet.
There is no single number — quote the band, not a figure. Without `--oracle` it
runs in half the pipelines and loses BOTH the red-green axis and ORACLE-MOVED,
which is most of the point.

AT THE AUTHORING RUN (bd drbq Inc 2b hand-back) and through both Rule-13 review
rounds, unchanged: 116 BOTH-ACCEPT-IDENTICAL, 12 BOTH-DECLINE, 16
DEGENERATE-FOLD, 1 OVER-DECLINE, 13 SUSPICIOUS — and **0 MISMATCH, 0
ORACLE-MOVED, 0 RED-GREEN-MISS, 0 HARNESS-ERROR, 0 stage-2b failures**. All 13
SUSPICIOUS are the ONE annotated class (`use=none`: the twin's register is dead,
so the DIAMOND spelling has no merge phi); the single OVER-DECLINE is
`a_phi_eq_src_region2_consts`, where a FOLLOWING phase region's
`taintedAngleGate` sees the still-present angle select in its derived base's
`cq_phi` and declines the module before the select is ever adjudicated. Both are
analysed in `CONTROL_IN_PLACE_INC2B_NOTES.md` §4.

AFTER THE CLEARANCE NARROWING (constant arms only), MEASURED: the **16
`angle=args` cells** move into the new EXPECTED-DECLINE-RUNTIME-ARMS class and
**all 142 other cells are line-for-line identical to the pre-narrowing table** —
102 BOTH-ACCEPT-IDENTICAL, 11 BOTH-DECLINE, 16 DEGENERATE-FOLD, 1 OVER-DECLINE,
12 SUSPICIOUS, 16 EXPECTED-DECLINE-RUNTIME-ARMS; still 0 MISMATCH / 0
ORACLE-MOVED / 0 RED-GREEN-MISS / 0 HARNESS-ERROR / 0 stage-2b failures. The 16
came from THREE classes, not one — 14 from BOTH-ACCEPT-IDENTICAL, 1 from
BOTH-DECLINE and 1 from SUSPICIOUS (`use=none`, the annotated dead-register
class) — which is why the totals do not move by 16 in a single row. They are
exactly the all-pairs cells that set `angle=args`: 2 (stem) + 5 (cond) + 5 (base)
+ 7 (use) = 19 pairings, of which 4 collapse onto the same default cell. Of the
16, the twin ACCEPTS in 14 and declines in 2 — and the 14 are not evidence of an
over-decline, for the reason in the `args` bullet above.

═══════════════════════════════════════════════════════════════════════════════
THE `cq_phi` SURFACE (`--phi-surface {register,void}`, bd
test_C_libtooling-3qlq Increment 1 — "retire the swap route")

`register` (DEFAULT) is the shipped 15-width `r = cq_phi(r, T)`. `void` is the
Increment-1 register-free branch phase `cq_phi(T)`, which needs an
`--include-dir` whose header declares the ONE extern `void cq_phi(double)` —
the mode REFUSES TO RUN otherwise, because a `register` header would take
`cq_phi(T)` as a one-argument call to a two-argument macro and the whole run
would read like a wall of compiler declines.

THE TWO STEMS SPLIT UNDER `void`, AND THIS INSTRUMENT SPLITS WITH THEM.

  * `stem=theta` (Ry) IS UNCHANGED IN SUBSTANCE. PRD D5 keeps
    `r = cq_theta(r, T)`, the 2b BY-DIFFERENCE lowering stands, its constant-arm
    narrowing stands, and the twin is still the manual `R(r,B); if (c) R(r,A-B)`
    diamond. What DOES change in those cells is the non-arm `cq_phi` spellings —
    `base=phialias` (`int r = cq_phi(p,.11)`) and `use=premark`/`postmark`
    (`int mark = cq_phi(r,.13)`) — which the surface rewriter turns into a plain
    ALIAS plus an UNCONTROLLED branch phase that PRD D2 DELETES. So `phialias`
    degenerates to `src` and the two `mark` cells lose their distinct rail. They
    are kept: a `void` run in which one of them differs from its degenerate
    sibling means the D2 deletion did not happen.

  * `stem=phi` (Rz) LOSES ITS TWIN ENTIRELY, AND THAT IS A MEASUREMENT, NOT A
    DESIGN CHOICE. PRD §3 lowers the void Rz angle select to the EXACT two-gate
    form `x(f); rz_i1(f,B); x(f); rz_i1(f,A)` — no subtraction, so the 2b
    by-difference twin is not the right oracle and the `2^-40` rounding fence is
    retired for this stem (run-time arms ADMITTED, PRD §3 / Rule-13 lens 5). The
    natural replacement twin is the flat PAIR OF DIAMONDS with the compare
    recomputed:

        if (q == 5) cq_phi(A);
        if (q != 5) cq_phi(B);

    MEASURED 2026-09-05, `clang -O1`, the void header, at CONSTANT arms
    (`0.9`/`0.3`) and at RUN-TIME arms (two `double` parameters): the two-diamond
    spelling and the `if/else` spelling produce WHOLE MODULES THAT ARE IDENTICAL
    — `diff` ignoring only `ModuleID`/`source_filename` — both folding to ONE
    `tail call void @cq_phi(double %s)` on `select i1 %c, double A, double B`.
    SimplifyCFG merges them before the pass ever sees a diamond.

    So there is NO COMPILABLE BYTE-IDENTITY TWIN for the Rz stem under `void`:
    every candidate spelling IS the subject. **Byte-identity is NOT available for
    that stem, and the PRD §10.2(d) GOLDEN-AUDIT SUBSTITUTION is the witness
    instead** — the requirement that each regenerated golden's diff be exactly
    the 2b pair `rz(h,B); rz_controlled(f,h,A-B)` -> the exact two-gate form and
    nothing else. This file does NOT attempt to reconstruct that; it would be a
    second, unvalidated spelling of the audit (Rule 14 in reverse). What it does
    instead is honest and small: it builds the SELECT side only, on both
    binaries, and reports `RZ-VOID-NO-TWIN(...)` with the disposition and — when
    the build under test accepts — the emitted `cqrt_rz_i1` lines VERBATIM, so a
    reader can check the two-gate shape against PRD §3 by eye. It asserts
    nothing about the unitary. A cell in that verdict is a RECORD, not a pass.

⚠ A PRE-INCREMENT-1 BINARY LEAVES THE CALL BEHIND. It has no concept of
`void @cq_phi(double)` — neither lowers nor deletes it — so the call survives
into the lowered IR and the module cannot link (no such runtime symbol, and this
epic adds none, PRD D3). MEASURED on the pre-3qlq oracle 52d7764. Reported
`PHI-UNLOWERED`, stages 2b/3/4 skipped: a DISPOSITION, not a harness error.
After Increment 1 it must not appear.

The build harness (`Side` / `build`) is IMPORTED from
`tools/inplace_twin_matrix.py` rather than re-implemented (Rule 14): one
spelling of "compile, lower, stage-2b, link, run", one place to fix it. The
`cq_phi` SURFACE REWRITER reaches this file through that same import — it is
defined once, in `tools/loop_twin_matrix.py`.
"""

import argparse
import concurrent.futures
import itertools
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inplace_twin_matrix import (Side, build, normalise,   # noqa: E402
                                 PHI_SURFACES, phi_surface_of_header,
                                 phi_void_source)  # (Rule 14)


# ─────────────────────────────── THE AXES ────────────────────────────────────

DEFAULT = dict(stem="theta", cond="eq", base="src", use="meas", angle="consts")

STEMS  = ["theta", "phi"]
CONDS  = ["eq", "ne", "sgt", "slt", "fcmp"]
BASES  = ["src", "chain", "mul", "add", "phialias"]
USES   = ["none", "meas", "ret", "derived", "region2", "premark", "postmark"]
ANGLES = ["consts", "args", "equal", "negative", "zero"]

AXES = [("stem", STEMS), ("cond", CONDS), ("base", BASES), ("use", USES),
        ("angle", ANGLES)]

QUICK_BASES = ["src", "mul", "phialias"]
QUICK_USES  = ["meas", "derived", "postmark"]

# (A, B) per angle axis value. `equal` folds the select away at -O1 and is
# reported DEGENERATE-FOLD rather than compared; it is kept as an axis value so
# the fold is OBSERVED rather than assumed.
ANGLE_PAIR = {
    "consts":   ("0.9", "0.3"),
    "args":     ("x", "y"),
    "equal":    ("0.9", "0.9"),
    "negative": ("0.3", "0.9"),
    "zero":     ("0.9", "0.0"),
}


def legal(c):
    # `postmark` needs an alias to mark, and `premark`/`postmark` both put a
    # `cq_phi` on the base's rail — meaningful for every base.
    return True


def name(c):
    return "a_%s_%s_%s_%s_%s" % (c["stem"], c["cond"], c["base"], c["use"],
                                 c["angle"])


def cells():
    """All-pairs: the union of every 2-D plane through DEFAULT."""
    out, seen = [], set()

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


def quick_cells():
    out = []
    for s, b, u in itertools.product(STEMS, QUICK_BASES, QUICK_USES):
        c = dict(DEFAULT)
        c.update(stem=s, base=b, use=u)
        out.append(c)
    return out


# ────────────────────────── THE C GENERATOR ──────────────────────────────────
#
# `form` is the ONLY difference between the two spellings of a cell:
#   "select" — `if (c) r = R(r, A); else r = R(r, B);`   (clang folds to a select)
#   "twin"   — `r = R(r, B); if (c) r = R(r, A - B);`    (a plain in-place diamond)
#
# The difference is computed OUTSIDE the `if` in the twin ON PURPOSE: a `double
# d = x - y;` inside the arm block would be a STRAY OP, which
# `inPlaceRotationArmTheta` refuses (it erases the arm block, so a stray op is
# silently dropped) — the twin would then decline for a reason that has nothing
# to do with the shape under test. With constants clang folds `d` away entirely,
# so the two spellings of an angle produce identical IR.

# THE TWIN'S PIVOT IS MEASURED, NOT ASSUMED, and getting it wrong is how this
# instrument cries wolf. `clang -O1` canonicalizes only ONE of the five
# predicates: `q != 5` becomes `icmp eq` with the select's two arms SWAPPED
# (`eq`/`sgt`/`slt`/`fcmp ogt` are all kept verbatim, arms unswapped — measured
# on all five). The by-difference twin must therefore pivot on the SELECT'S OWN
# polarity, i.e. for `ne` it is written `r = R(r, A); if (q == 5) r = R(r, B-A);`
# — the `==` form with a NEGATIVE difference. Writing the twin with the source's
# own `!=` instead produces a `cqrt_x`-bracketed negated diamond, which is a
# DIFFERENT (and equally correct) decomposition and would report MISMATCH on
# eleven perfectly good cells. Re-measure this table if the frontend moves.
COND_C   = {"eq": "q == 5", "ne": "q != 5", "sgt": "q > 5", "slt": "q < 5",
            "fcmp": "g > 2.0"}
TWIN_C   = dict(COND_C, ne="q == 5")   # the SELECT's post-canonicalization test
TWIN_SWAP = {"ne"}                     # …and its arms, swapped to match


def gen(c, form, surface="register"):
    R = "cq_theta" if c["stem"] == "theta" else "cq_phi"
    A, B = ANGLE_PAIR[c["angle"]]
    fp_cond = c["cond"] == "fcmp"

    L = []
    # `noinline` is LOAD-BEARING, not tidiness. Without it `clang -O1` inlines
    # `slice` into `main`, whose `(void)` discard makes the rotated register DEAD
    # in that second copy — and a dead register leaves no merge phi, so the TWIN's
    # diamond is OffPattern there and declines `control flow` while the select
    # form (which has no CFG to be off-pattern) lowers. That is a property of the
    # harness, not of the increment, and it produced 20+ spurious SUSPICIOUS
    # cells before it was found.
    L.append("__attribute__((noinline)) int slice(double x, double y, "
             "double d, double nd) {")
    L.append("    int q = cq_theta(3, 0.5);")
    L.append("    int p = cq_theta(7, 0.25);")
    if fp_cond:
        L.append("    double g = cq_theta(1.5, 0.375);")

    # ---- the rotated BASE ---------------------------------------------------
    if c["base"] == "src":
        L.append("    int r = p;")
    elif c["base"] == "chain":
        L.append("    int r = cq_theta(p, 0.125);")
    elif c["base"] == "mul":
        L.append("    int r = p * 5;")
    elif c["base"] == "add":
        L.append("    int r = p + 5;")
    elif c["base"] == "phialias":
        L.append("    int r = cq_phi(p, 0.11);")

    # ---- an alias RECORD, read before (premark) or after (postmark) ---------
    if c["use"] in ("premark", "postmark"):
        L.append("    int mark = cq_phi(r, 0.13);")
        if c["use"] == "premark":
            L.append("    int em = cq_measure(mark);")

    # ---- the construct under test ------------------------------------------
    if form == "select":
        L.append("    if (%s) r = %s(r, %s); else r = %s(r, %s);"
                 % (COND_C[c["cond"]], R, A, R, B))
    else:
        hi, lo = (B, A) if c["cond"] in TWIN_SWAP else (A, B)
        # THE `args` ANGLE TAKES ITS DIFFERENCE AS A PARAMETER, and that is a
        # measured necessity rather than a shortcut. Written as
        # `double ddi = x - y;` before the branch, `clang -O1` SINKS the `fsub`
        # INTO the arm block (it is only used there) — and a stray op in an arm
        # block is exactly what `inPlaceRotationArmTheta` refuses, because the
        # flatten ERASES that block. The twin would then decline `control flow`
        # for a reason that has nothing to do with the shape under test (11
        # spurious SUSPICIOUS cells before it was found). `main` passes
        # `1.25 - 0.75`, so `d` WAS BIT-IDENTICAL to the `fsub` the select form's
        # emitter used to create, and the trace — which prints the angle's runtime
        # value — could not tell them apart.
        #
        # ⚠ SINCE THE CLEARANCE NARROWING THE SELECT SIDE OF THESE CELLS DECLINES
        # (constant arms only, finding F-11 / owner option (2)), so nothing is
        # compared here any more: the cells report EXPECTED-DECLINE-RUNTIME-ARMS.
        # The twin still compiles, and that asymmetry is exactly the reason it was
        # never an oracle — it takes the difference IN and performs no
        # subtraction, whereas the program a user would write does the `fsub`
        # itself and declines on both binaries. `control_angle_select_ry_arg_angles.ll`,
        # which used to pin the classical `fsub` INSTRUCTION, has been replaced by
        # the decline fixture `control_angle_select_reject_runtime_arms.ll`.
        if c["angle"] == "args":
            # `d` is `x - y`; a SWAPPED (ne) pivot needs `y - x`, so negate it.
            # Getting this wrong shows up as a MISMATCH on exactly the
            # ne x args cell, which is how it was caught.
            L.append("    double dlo = %s;" % lo)
            # `d` is `x - y` and `nd` is `y - x`, BOTH passed in: writing
            # `-d` instead would leave an `fneg` that `clang -O1` SINKS into the
            # arm block, i.e. the same stray-op decline this parameter exists to
            # avoid, one operation over. Caught as a SUSPICIOUS on exactly the
            # ne x args cell.
            L.append("    double ddi = %s;"
                     % ("nd" if c["cond"] in TWIN_SWAP else "d"))
        else:
            L.append("    double dlo = %s;" % lo)
            L.append("    double ddi = (%s) - (%s);" % (hi, lo))
        L.append("    r = %s(r, dlo);" % R)
        L.append("    if (%s) r = %s(r, ddi);" % (TWIN_C[c["cond"]], R))

    # ---- the POST-GATE consumer --------------------------------------------
    tail = []
    if c["use"] == "none":
        tail.append("    return cq_measure(q);")
    elif c["use"] == "meas":
        tail.append("    return cq_measure(q) + cq_measure(r);")
    elif c["use"] == "ret":
        tail.append("    return r;")
    elif c["use"] == "derived":
        tail.append("    int s = r + 1;")
        tail.append("    return cq_measure(q) + cq_measure(s);")
    elif c["use"] == "region2":
        tail.append("    if (q == 6) r = %s(r, 0.77);" % R)
        tail.append("    return cq_measure(q) + cq_measure(r);")
    elif c["use"] == "premark":
        tail.append("    return cq_measure(q) + cq_measure(r) + em;")
    elif c["use"] == "postmark":
        tail.append("    return cq_measure(q) + cq_measure(r) + cq_measure(mark);")
    L += tail
    L.append("}")
    L.append("int main(void) { (void) slice(1.25, 0.75, 1.25 - 0.75, "
             "0.75 - 1.25); return 0; }")
    out = "\n".join(L) + "\n"
    # The bd 3qlq surface rewrite is applied to the FINISHED text of BOTH forms,
    # in ONE place, so a surface artefact can never look like a select-vs-twin
    # difference. `register` returns it byte-unchanged.
    return phi_void_source(out) if surface == "void" else out


# ────────────────────────────── ONE CELL ─────────────────────────────────────

def run_cell(cfg, c):
    nm = name(c)
    work = (os.path.join(cfg.keep, nm) if cfg.keep
            else tempfile.mkdtemp(prefix="cqas_"))
    if cfg.keep:
        os.makedirs(work, exist_ok=True)
    sf = cfg.phi_surface
    # THE Rz STEM HAS NO TWIN UNDER `void`, MEASURED (see the docstring's
    # `cq_phi` SURFACE section): `clang -O1` folds every candidate spelling —
    # including the two-diamond one with the compare recomputed — into the SAME
    # single call on an angle `select`, whole modules identical. So the twin
    # pipelines are not built at all rather than built and quietly ignored: a
    # twin that is byte-identical to its subject is not an oracle, and running
    # it would print a green `BOTH-ACCEPT-IDENTICAL` that means nothing.
    no_twin = (sf == "void" and c["stem"] == "phi")
    try:
        sel_new = build(cfg, work, nm + "_sel_new", gen(c, "select", sf))
        twn_new = (None if no_twin
                   else build(cfg, work, nm + "_twn_new", gen(c, "twin", sf)))
        sel_old = (build(cfg, work, nm + "_sel_old", gen(c, "select", sf),
                         cfg.oracle)
                   if cfg.oracle else None)
        twn_old = (None if no_twin else
                   (build(cfg, work, nm + "_twn_old", gen(c, "twin", sf),
                          cfg.oracle) if cfg.oracle else None))
        # DEGENERATE-FOLD is a property of the stage-1 IR, so read it there.
        s1 = os.path.join(work, nm + "_sel_new.s1.ll")
        degenerate = (os.path.exists(s1)
                      and "select i1" not in open(s1).read())
    finally:
        if not cfg.keep:
            shutil.rmtree(work, ignore_errors=True)
    return nm, c, classify(sel_new, twn_new, sel_old, twn_old, degenerate,
                           c["use"], c["angle"], no_twin)


def _resid(side):
    """How to read one side's residual-`cq_phi` state, in words. A side that
    DECLINED was never asked — reporting `0` there would say "this side lowered
    the void surface cleanly", which is the opposite of what happened."""
    if not getattr(side, "phi_asked", False):
        return "not asked (%s)" % ("declined" if side.exit else "harness error")
    return "%d residual" % side.phi_unlowered


def _diag(s):
    return (s.diag or "").replace("cq controlled lowering: ", "") \
                         .replace(" under quantum control", "")


def classify(sel, twn, sel_old, twn_old, degenerate, c_use="", c_angle="",
             no_twin=False):
    R = dict(verdict="", note="", diff="")

    for tag, s in (("select@new", sel), ("twin@new", twn),
                   ("select@old", sel_old), ("twin@old", twn_old)):
        if s is not None and s.error:
            R["verdict"] = "HARNESS-ERROR"
            R["note"] = "%s: %s" % (tag, s.error)
            return R

    # bd 3qlq Inc 1 — asked EARLY, because a side in this state lowered cleanly
    # and simply still names a symbol nothing defines, so there is no trace to
    # compare and no diagnostic to report. A pre-Increment-1 binary neither
    # lowers nor deletes `void @cq_phi`. A disposition, not a harness error.
    sides = (("select@new", sel), ("twin@new", twn),
             ("select@old", sel_old), ("twin@old", twn_old))
    if any(s is not None and s.phi_unlowered for _, s in sides):
        R["verdict"] = "PHI-UNLOWERED"
        # Every side is reported, not only the ones with a residual: a side that
        # DECLINED was never asked, and printing only the non-zero counts would
        # let a reader take the silence for a clean lowering.
        R["note"] = ("residual `call void @cq_phi` in the LOWERED IR: "
                     + ", ".join("%s %s" % (t, _resid(s))
                                 for t, s in sides if s is not None))
        return R

    # STRICT stage 2b on every side that lowered. `twn` is None for a cell whose
    # stem has no twin under `--phi-surface void` (bd 3qlq Inc 1), so the side is
    # skipped rather than asked — there is nothing to ask.
    bad2b = [t for t, s in (("select@new", sel), ("twin@new", twn))
             if s is not None and s.exit == 0
             and ("violation(s), 0 unproven" not in s.pair)]
    if bad2b:
        R["note"] = "STAGE2B " + ",".join(bad2b)

    if degenerate:
        R["verdict"] = "DEGENERATE-FOLD"
        return R

    # ── THE Rz STEM UNDER `void`: A RECORD, NOT A PASS. ─────────────────────
    # There is no compilable byte-identity twin (measured — see the docstring),
    # so this branch asserts nothing about the unitary. It records the SELECT
    # side's disposition on both binaries and, when the build under test accepts,
    # prints the emitted `cqrt_rz_i1` lines VERBATIM so a reader can check the
    # PRD §3 two-gate shape `x(f); rz_i1(f,B); x(f); rz_i1(f,A)` by eye. The
    # witness for that stem is the PRD §10.2(d) golden-audit substitution, which
    # this file deliberately does not re-implement.
    if no_twin:
        if sel.exit != 0:
            R["verdict"] = "RZ-VOID-NO-TWIN-DECLINE"
            R["note"] = "select declines: " + _diag(sel)
            return R
        if sel_old is not None and sel_old.exit == 0:
            R["verdict"] = "RED-GREEN-MISS"
            R["note"] = "select@old ACCEPTED — the shape is not new"
            return R
        gates = [l for l in (sel.trace or []) if l.startswith("cqrt_rz_i1(")]
        xs = sum(1 for l in (sel.trace or []) if l.startswith("cqrt_x("))
        R["verdict"] = "RZ-VOID-NO-TWIN-ACCEPT"
        R["note"] = ("byte-identity NOT available for this stem (the twin folds "
                     "to the subject); PRD §10.2(d) is the witness. %d rz_i1, "
                     "%d cqrt_x: %s"
                     % (len(gates), xs, " | ".join(gates) or "<none>"))
        return R

    if twn_old is not None and twn.exit == 0 and twn_old.exit == 0 \
            and normalise(twn.trace) != normalise(twn_old.trace):
        R["verdict"] = "ORACLE-MOVED"
        R["diff"] = _difftxt(twn_old.trace, twn.trace)
        return R
    if twn_old is not None and twn.exit != twn_old.exit:
        R["verdict"] = "ORACLE-MOVED"
        R["note"] = "twin disposition moved: old=%s new=%s" % (
            twn_old.exit, twn.exit)
        return R

    # THE `args` AXIS DECLINES BY DESIGN — the Rule-13 CLEARANCE narrowing (bd
    # `test_C_libtooling-drbq`, finding F-11, owner option (2): the angle-select
    # accept is CONSTANT ARMS ONLY). Asked BEFORE the SUSPICIOUS / OVER-DECLINE /
    # BOTH-DECLINE triage so the expected disposition is reported as itself
    # instead of as a scope surprise, and asked ONLY when the select side
    # DECLINED, so it can never mask a MISMATCH (which needs both sides to
    # accept) or a SUSPICIOUS (which needs the select to accept).
    #
    # THE CELLS ARE DELIBERATELY KEPT, NOT DELETED: they are the red-green
    # witness that a run-time arm declines, and the twin's disposition is still
    # printed in the note. Read that twin verdict carefully — an accepting twin
    # here is NOT evidence that the select form is over-declining, because this
    # harness passes the difference in as a PARAMETER (`d` / `nd` from `main`)
    # and therefore performs NO SUBTRACTION AT ALL. The natural manual twin, the
    # one that writes `A - B` itself, declines `control flow` on BOTH binaries
    # (clearance observation 1) — so there is no compilable oracle for this class
    # anywhere, which is a large part of why it was narrowed away.
    if sel.exit != 0 and c_angle == "args" \
            and "rotation angle" in (sel.diag or ""):
        R["verdict"] = "EXPECTED-DECLINE-RUNTIME-ARMS"
        R["note"] = ("select declines: " + _diag(sel) + "  [expected: constant "
                     "arms only, clearance F-11 / owner option (2); twin "
                     + ("ACCEPTS — but it takes the difference as a PARAMETER "
                        "and subtracts nothing" if twn.exit == 0
                        else "declines: " + _diag(twn)) + "]")
        return R
    if sel.exit == 0 and twn.exit != 0:
        R["verdict"] = "SUSPICIOUS"
        R["note"] = "twin declines: " + _diag(twn) + _known(c_use, twn)
        return R
    if sel.exit != 0 and twn.exit == 0:
        R["verdict"] = "OVER-DECLINE"
        R["note"] = "select declines: " + _diag(sel)
        return R
    if sel.exit != 0 and twn.exit != 0:
        R["verdict"] = "BOTH-DECLINE"
        a, b = _diag(sel), _diag(twn)
        R["note"] = a if a == b else "select=[%s] twin=[%s]" % (a, b)
        return R

    if sel_old is not None and sel_old.exit == 0:
        R["verdict"] = "RED-GREEN-MISS"
        R["note"] = "select@old ACCEPTED — the shape is not new"
        return R

    if normalise(sel.trace) != normalise(twn.trace):
        R["verdict"] = "MISMATCH"
        R["diff"] = _difftxt(twn.trace, sel.trace)
        return R
    R["verdict"] = "BOTH-ACCEPT-IDENTICAL"
    return R


# ANALYSIS RECORDED AT AUTHORING TIME, NOT A SUPPRESSION. A cell that matches one
# of these still prints `!!` and still counts in the SUSPICIOUS tally; it just
# carries the reproduction. A SUSPICIOUS cell WITHOUT an annotation has never
# been looked at and must be reproduced standalone before it is ranked.
def _known(use, twn):
    if use == "none" and "control flow" in (twn.diag or ""):
        return ("  [known: the twin's register is DEAD, so `clang -O1` leaves "
                "the diamond with NO merge phi and `recoverRegion` refuses it "
                "OffPattern. A property of the DIAMOND spelling, not of the "
                "select — the same pre-existing behaviour recorded in "
                "CONTROL_IN_PLACE_INC2B_NOTES.md §4-C and pinned by "
                "control_angle_select_ry_dead_base_frozen.ll, whose hand-IR twin "
                "(which keeps the phi) emits the identical stream.]")
    return ""


def _difftxt(a, b):
    import difflib
    return "\n".join(list(difflib.unified_diff(
        normalise(a), normalise(b), "twin", "select", lineterm=""))[:24])


def _star(t):
    return run_cell(*t)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--include-dir", default="",
                    help="the directory holding CQ.h. Default `<root>/include`. "
                         "Under --phi-surface void it MUST point at a header "
                         "whose cq_phi is the ONE register-free extern "
                         "`void cq_phi(double)` (bd 3qlq Inc 1, PRD §4.1).")
    ap.add_argument("--phi-surface", choices=PHI_SURFACES, default="register",
                    help="the `cq_phi` FRONTEND surface the cells are generated "
                         "against (bd test_C_libtooling-3qlq Increment 1). "
                         "`register` (DEFAULT) is the shipped 15-width "
                         "`r = cq_phi(r, T)`; `void` is the register-free branch "
                         "phase `cq_phi(T)`. Under `void` the Rz stem has NO "
                         "TWIN — measured: -O1 folds every candidate spelling "
                         "into the subject — so its cells are RECORDS "
                         "(`RZ-VOID-NO-TWIN-*`), not passes. See the module "
                         "docstring's `cq_phi` SURFACE section.")
    ap.add_argument("--llvm", default="/usr/local/opt/llvm@19/bin")
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--only", default="")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--quick", action="store_true",
                    help="a smoke subset (NOT a green matrix)")
    ap.add_argument("--keep", default="")
    ap.add_argument("--out", default="")
    ap.add_argument("--oracle", default="",
                    help="path to a PRE-2b `cq-opt`. With it every cell also "
                         "records that the SELECT form was RED there (Rule 12 "
                         "red-green) and that the TWIN's own trace did not move "
                         "between the two binaries (ORACLE-MOVED).")
    cfg = ap.parse_args()
    if cfg.phi_surface == "void":
        hdr = os.path.join(cfg.include_dir or os.path.join(cfg.root, "include"),
                           "CQ.h")
        try:
            text = open(hdr).read()
        except OSError as e:
            sys.stderr.write("--phi-surface void: cannot read %s (%s)\n"
                             % (hdr, e))
            return 2
        # A `register` header would take `cq_phi(T)` as a ONE-argument call to a
        # TWO-argument _Generic macro; clang would reject every cell at stage 1
        # and the run would read like a wall of compiler declines.
        #
        # ASKED BY `phi_surface_of_header`, THE ONE SPELLING IN THE TREE (Rule
        # 14, and the same import that already brings `phi_void_source` here).
        # It was a LITERAL substring test `"void cq_phi(double" not in text`,
        # duplicated in all three instruments, and the SHIPPED include/CQ.h
        # spells the declaration column-aligned — `void                cq_phi
        # (double angle);` — so all three REFUSED the very header they require
        # and said it was a `register`-surface one (bd 3qlq Inc 1, round-1 review
        # finding F-L5-7(b); MEASURED here on 2026-09-05, where it stopped the
        # POST run of this instrument dead). The classifier strips C comments
        # first, so the shipped header's own prose about the retired
        # `cq_phi_<sfx>(x, angle)` family cannot flip the answer, and
        # `loop_twin_matrix_quarantine_test.py` exercises it against the REAL
        # include/CQ.h.
        hdr_surface = phi_surface_of_header(text)
        if hdr_surface != "void":
            sys.stderr.write(
                "--phi-surface void: %s declares the `%s` cq_phi surface, not "
                "`void`.\n  Every cell would fail at STAGE 1 and the wall of "
                "clang errors would read like\n  a wall of lowering declines. "
                "Point --include-dir at a header whose cq_phi is\n  the ONE "
                "register-free extern `void cq_phi(double)` (PRD §4.1) — the "
                "shipped\n  include/CQ.h is one.\n" % (hdr, hdr_surface))
            return 2
    if cfg.oracle and not os.access(cfg.oracle, os.X_OK):
        sys.stderr.write("oracle not executable: %s\n" % cfg.oracle)
        return 2
    cfg.clang = os.path.join(cfg.llvm, "clang")
    cfg.cqopt = os.path.join(cfg.root, "build/ir-pass/cq-opt")
    cfg.include = cfg.include_dir or os.path.join(cfg.root, "include")
    cfg.pairchk = os.path.join(cfg.root, "tools/free_pairing_check.py")
    cfg.templates = os.path.join(cfg.root, "build/runtime/libcq_templates.a")
    cfg.runtime = os.path.join(cfg.root, "build/runtime/libcq_runtime.a")
    cfg.ld = os.environ.get("CQ_LD",
                            os.path.join(cfg.root, "build/tests/e2e/cq_link.sh"))

    pool = quick_cells() if cfg.quick else cells()
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

    BAD = ("SUSPICIOUS", "MISMATCH", "ORACLE-MOVED", "HARNESS-ERROR",
           "RED-GREEN-MISS")
    lines, tally = [], {}
    for nm, c, R in sorted(res):
        tally[R["verdict"]] = tally.get(R["verdict"], 0) + 1
        flag = "!!" if (R["verdict"] in BAD or R["note"].startswith("STAGE2B")) \
               else "  "
        lines.append("%s %-46s %-22s %s" % (flag, nm, R["verdict"], R["note"]))
        if R["diff"]:
            for l in R["diff"].splitlines():
                lines.append("      " + l)
    out = "\n".join(lines)
    print(out)
    print("\n=== TALLY (%s%s, %d cells) ===" %
          ("QUICK" if cfg.quick else "ALL-PAIRS",
           ", --phi-surface void" if cfg.phi_surface == "void" else "",
           len(res)))
    for k in sorted(tally):
        print("  %-24s %d" % (k, tally[k]))
    bad = sum(tally.get(k, 0) for k in BAD)
    print("  %-24s %d" % ("--- flagged", bad))
    if cfg.out:
        open(cfg.out, "w").write(out + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
