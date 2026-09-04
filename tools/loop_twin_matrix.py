#!/usr/bin/env python3
"""loop_twin_matrix.py — the ROLLED-EQUALS-UNROLLED witness, as a MATRIX.

bd test_C_libtooling-8h7d.5, Rule-13 ROUND 4. Phase 7.3 Increment 3's whole
correctness claim is one sentence — "the rolled loop emits the same gate stream
its hand-unrolled twin does" — and until this gate existed it was witnessed by
FOUR hand-picked e2e slice pairs, every one of which puts the tainted region
FIRST in the loop body. That is one cell of a matrix, and it is the cell where
the round-4 finding is invisible.

WHAT THIS GATE IS FOR, stated as the defect it would have caught. Move ONE
`cq_theta` to the front of the body:

    for (i < 2) { a = cq_theta(a, 0.25);
                  if (sqrt(a + 3.) <= 3.5) { a = cq_phi(a, PI); }
                  a = cq_theta(a, -0.5); }

and the M-B interior partition stopped discharging the oracle's ancilla chain.
`opt` exited 0. `opt -verify` was clean. STRICT `free_pairing_check.py` reported
zero violations — it counts `cqrt_alloc` mints, and the leaked rails are
TEMPLATE-minted, so it cannot see them (read that file's header). Five of the
eleven affected cells emitted NO diagnostic at all. The rolled trace was simply
shorter than its twin's, by exactly the missing discharge lines, and every other
gate in the 285-entry suite stayed green.

So the matrix is not extra coverage of a covered property. It is the ONLY
instrument in the tree that can see this class, and the shipped slices are the
cell it is blind in.

WHAT IT CHECKS, per cell, and each of the three is a separate failure:
  (i)   DISPOSITION MISMATCH — the rolled form accepts and the unrolled declines,
        or vice versa. Both diagnostics are printed.
  (ii)  TRACE DIVERGENCE — both accept and the runtime traces differ. The first
        differing line is printed, with per-side counts of `_unc`, `cqrt_free`
        and handle mints.
  (iii) ASYMMETRIC DIAGNOSTIC — an accepted rolled cell carries a stderr warning
        its twin does not.
Plus the table check: every cell's verdict must equal the committed one in
`tools/loop_twin_matrix.expected.txt`. A cell that changes disposition is a RED,
never a silent drift (Rule 12) — regenerate the table deliberately with
`--regenerate`, never by reflex, and say in the commit message which cells moved
and why.

THE STAGES ARE THE SLICES' STAGES, deliberately replicated rather than shared:
`clang -O1 -emit-llvm` -> `opt -passes=cq-lowering` -> STRICT
`free_pairing_check.py` (no `--allow-unproven`) -> link (templates BEFORE
runtime) -> run. `run_slice.sh` is not reused because it ends in a golden
byte-diff and these cells have no goldens — the twin IS the golden.

WHY THE TRACES CAN BE COMPARED AT ALL. Both sides mint their handles in the same
order from the same source stream, so a correct rolled lowering produces a trace
that is byte-identical to its unrolled twin's, handle numbering included. That is
a strong property and it is the point: it leaves no room for "equivalent but
different".

THE ONE WAY THAT PROPERTY CAN BREAK WITHOUT A COMPILER BUG, recorded before it
bites someone (round-5 reviewer caveat, bd 8h7d.5). The two sides are the same
source text but not the same PROGRAM SHAPE, and `clang -O1` optimizes the flat
spelling harder: a body whose gates carry CONSTANT immediates can fold ACROSS the
repetition on the unrolled side only — `a = a * 3;` twice in a row becomes
`a * 9`, so the unrolled trace legitimately has one fewer gate. That is a
`TRACE-DIVERGENCE` caused by the GENERATOR, not by the loop lowering.

THE FOURTH AXIS — RECORD (bd drbq Inc 2a round-1 review, L1 §3.8). Until then
this matrix had NO `int mark = a;` in any of its 120 cells, and the 8h7d.5 F-1 and
F-3 findings — two of the three CONFIRMED silent miscompiles that machinery
produced — were entirely about rail RECORDS. See the `RECORD` table below for the
three shapes and for why the axis is crossed with a declared sub-grid rather than
with the whole product. The 120 record-free cells keep their names and verdicts
exactly (`m_<prefix>_<region>_<suffix>`); the 36 new ones carry a fourth segment.

THE FIFTH AXIS — CONTROLLED Ry ARM (bd test_C_libtooling-drbq Inc 3, drbq.4).
WRITTEN AND REGENERATED AT HEAD 1bdaa60, BEFORE ANY LOWERING EXISTS, WHICH IS THE
WHOLE POINT: the fixture `ir-pass/test/control_inplace_ry_reject_in_loop.ll` says
in its own header that Inc 3 "must re-ask them and add the shape as a
`tools/loop_twin_matrix.py` axis FIRST", and bd
[`control-in-loop-shipped-8h7d5`] says the same. So the table this axis writes
today is a table of DECLINES, and the diff it produces when Inc 3 lands IS the
witness. A witness regenerated after the implementation would only be able to say
that the implementation agrees with itself.

WHAT IT IS FOR, stated as the defect it would catch. Every REGION cell above
rotates the ONE register `a` with `cq_phi` — a DIAGONAL gate on the register the
condition reads, which is exactly the case `LoopLowering`'s rail machinery
(`collectRailGates` / `railGateBetween` / `staleRailRecordRead`) was written and
adversarially cleared against. Inc 3's shape is different in the one way that
matters: a `cq_theta` (Ry) arm on a SECOND register `r` whose physical wire is
DISJOINT from the condition register (control-in-place-PRD §4, R1–R7), lowered
CONTROL-IN-PLACE to `cqrt_ry_<W>_controlled(f, r, θ)` rather than through the swap
route — because `Ry|0⟩ ≠ |0⟩` hands the inactive work rail back DIRTY and ENTANGLED
(Rules 6/8). That gate RELABELS the loop-carried register once per trip, and all
three of those `LoopLowering` predicates recognize an in-place Ry by its
`@cq_theta_` spelling with the wire at ARG 0 — the hoisted controlled form puts
the wire at arg 1. An Inc-3 that lifts the loop decline without re-asking them
therefore emits a rolled stream whose rail relabelling is invisible to the
staleness fence, on a register the fence does not know is a rail: `opt` exit 0,
verify-clean, and STRICT stage 2b clean (the F-4 lesson — 2b counts `cqrt_alloc`
mints, and it cannot see a gate that names the wrong argument either). The rolled
trace would simply differ from its twin's. That is the class, and this axis is
where it becomes visible.

WHY A DECLARED SUB-GRID AGAIN, not the product. The five axes multiply to
thousands of cells and the gate already costs ~120s of the suite's ~130-230s
band. The sub-grids (`RY_*` below) keep: every REGION spelling crossed with the
a-register gates that can relabel the CONDITION wire; the REGION spellings that
matter to the uncompute spine (direct compare, and the derived `sqrt` one that
brings four template rails in) crossed with the FULL second-register gate axis;
the three RECORD shapes on the ROTATED register `r` (the 8h7d.5 F-1 / F-3 / F1
programs, moved off the condition register onto the rotated one); one triple
with the record on `a` while the arm rotates `r`; and two singleton DECLINE
controls. 117 cells.

AND ONE THING THAT HAD TO BE MEASURED RATHER THAN DESIGNED (Rule 11), because it
decides whether most of those cells witness anything at all. An Ry arm rotates a
register the condition does NOT read — that is the accept shape — so `a` is
LOOP-INVARIANT in any body that has no a-register gate beside the region, and a
literal-constant compare on a loop-invariant register gets HOISTED: LICM lifts it
to the preheader on the ROLLED side, CSE merges the two repetitions' compares on
the UNROLLED side. Both sides then show the pass `compare … Ry on r … branch`,
and the kjd1 gate-2c window guard is not wire-aware, so it declines
`condition predates a non-diagonal gate` on BOTH — an inert cell that Inc 3
cannot flip. The FIRST regeneration of this axis came out 72-of-109 inert that
way. The fix is the one the paragraph above prescribes: an OPAQUE compare
threshold read from the already-`volatile` `off`, which defeats the hoist and the
CSE without changing the tainted lineage by one instruction. See the
`oeq`/`one`/`oder` entries. The literal-constant spellings are KEPT in full —
their a-gated cells are live on their own, and their inert cells now RECORD the
hoist decline, which is itself something Inc 3 needs to know: lifting the R7 loop
fence alone does not make a loop-invariant-condition Ry arm compile.

THE BLIND SPOT, said plainly because it is structural and not fixable here. This
matrix's ORACLE is the UNROLLED twin, and the unrolled twin of an Ry-arm cell is
itself the Inc-1 FLAT control-in-place lowering. So the axis can only witness
"rolled ≠ flat". A defect that Inc 1 and Inc 3 SHARE — a wrong `cqrt_ry_<W>_-
controlled` polarity, a missed R4 wire aliasing, a freeze that should have fired
on both sides — is byte-identical on both and this gate reports
`ACCEPT-IDENTICAL`. That property is not new (it is true of every axis here), but
it bites harder for Ry: the Rz axes' unrolled side is the long-shipped swap route,
whereas Ry's is one increment old. The flat side's own witnesses are the Inc-1
lit family (`ir-pass/test/control_inplace_ry_*.ll`) and
`tests/e2e/slice_control_inplace_ry.c`; they are not replaced by anything here.

A SECOND, SMALLER ONE: at HEAD nearly every new cell is `UNROLLED-ONLY`, so its
ROLLED side never reaches stage 3 or 4 and the cell's TRACE comparison has never
run. Those cells are today a disposition witness only. They become trace
witnesses the moment Inc 3 flips them, which is precisely when the trace
comparison is the thing you want — but do not read a green `UNROLLED-ONLY` row as
"the traces were checked".

NO SHIPPED AXIS HAS ONE — every prefix/suffix immediate here is either the
`volatile int off` or a rotation angle (angles are classical operands and never
fold into each other), which is why all 120 cells are meaningful today. A FUTURE
AXIS MAY. When one appears, the honest response is to make the immediate opaque
(`volatile`, as `off` already is) so the two sides are shapes of the same
computation again. NEVER bless a divergence in the expected table: this gate has
exactly one job, and a table entry that says "this pair may differ" retires it.
"""

import argparse
import concurrent.futures
import itertools
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# ── THE MATRIX ──────────────────────────────────────────────────────────────
# PREFIX x REGION x SUFFIX over one loop body. The axes are chosen so that each
# one moves a DIFFERENT part of the lowering:
#
#   PREFIX — what stands on the rail BEFORE the region. `none` is the shipped
#     slices' cell. `ry` is the finding: a non-diagonal in-place gate whose next
#     activation sits before the region's first recovered gate. `rz` is its
#     DIAGONAL control (it is admitted by `preservesBorrowedParent`, so it must
#     never have been affected — and it never was, which is what identified the
#     axis). `add`/`xor` are the dtzb in-place VALUE gates, the same position with
#     a different opcode family.
#   REGION — how the condition is built. `eq`/`eq0`/`gt` are direct compares on
#     the rail; `der` is a DERIVED condition (`sqrt(a+3.)`), which is the one that
#     brings the uncompute spine in with four template rails; `ifelse` is the
#     two-armed phase region. `range` is the TWO-SIDED test `a > 5 && a < 20`,
#     added by the round-5 cleanup (bd 8h7d.5): `clang -O1` canonicalizes it to
#     `%t = add %q, -6; icmp ult %t, 14`, so the condition temp wears the dtzb
#     IN-PLACE SHAPE on the rail — which is the OD-A oracle, the exact shape
#     round 4 fixed, and it was NOT among the shipped 100 cells. Measured at the
#     time it was added: 11 of its 20 cells were DIVERGENT at round 3 and all 20
#     are IDENTICAL at HEAD, so the axis is a live witness for OD-A and not
#     decoration.
#   SUFFIX — what stands on the rail AFTER the region, which is where the
#     discharge point lands.
PREFIX = {
    "none": "",
    "ry": "        a = cq_theta(a, 0.25);\n",
    "rz": "        a = cq_phi(a, 0.125);\n",
    "add": "        a = a + off;\n",
    "xor": "        a = a ^ 9;\n",
}
REGION = {
    "eq": "        if (a == 5) { a = cq_phi(a, M_PI); }\n",
    "eq0": "        if (a == 0) { a = cq_phi(a, M_PI); }\n",
    "der": "        if (sqrt(a + 3.) <= 3.5) { a = cq_phi(a, M_PI); }\n",
    "ifelse": "        if (a == 5) { a = cq_phi(a, M_PI); } else { a = cq_phi(a, 0.5); }\n",
    "gt": "        if (a > 5) { a = cq_phi(a, M_PI); }\n",
    "range": "        if (a > 5 && a < 20) { a = cq_phi(a, M_PI); }\n",
}
SUFFIX = {
    "none": "",
    "ry": "        a = cq_theta(a, -0.5);\n",
    "rz": "        a = cq_phi(a, -0.125);\n",
    "add": "        a = a + off;\n",
}

# ── THE RECORD AXIS ─────────────────────────────────────────────────────────
# bd test_C_libtooling-drbq Inc 2a, round-1 review (L1 §3.8). THE SHIPPED 120
# CELLS HAVE NO `int mark = a;` ANYWHERE, and the 8h7d.5 F-1 and F-3 findings —
# two of the three CONFIRMED silent miscompiles that machinery produced — were
# ENTIRELY about rail RECORDS: a value read at a position where the register no
# longer holds it. The PREFIX/REGION/SUFFIX product cannot express one, so the
# instrument that exists to see the loop lowering's worst class was blind to the
# shape those defects lived in.
#
# Each record is (a declaration hoisted OUT of the loop, a line before the
# region, a line after it, and what the return statement additionally measures).
# THE DECLARATION IS OUTSIDE THE LOOP DELIBERATELY: an in-body `int mark = a;`
# makes the hand-unrolled twin redeclare `mark` in ONE scope and `clang` rejects
# it — a harness artifact that cost the round-1 reviewer 8 of 32 cells, and it is
# designed out here rather than explained away.
#
#   premark   — the F-1 shape. The record is taken from the register BEFORE the
#               region and read AFTER THE LOOP. Note this is ALSO the
#               "record of the condition register" case: every REGION spelling in
#               this grid builds its condition from `a`, so `mark` is by
#               construction a record of the register the condition reads.
#   postmark  — the F-3 shape, one hop the other way: the record is taken AFTER
#               the region, so it names the post-gate register and any later
#               in-place gate (the SUFFIX) makes it stale.
#   bodyread  — the round-1 F1 program itself (`acc = mark * 7;`): the record is
#               read INSIDE the body, i.e. the read and the relabelling gate are
#               separated by the back edge rather than by straight-line position.
RECORD = {
    "none": {"decl": "", "pre": "", "post": "", "tail": ""},
    "premark": {"decl": "    int mark = 0;\n",
                "pre": "        mark = a;\n", "post": "",
                "tail": " + cq_measure(mark)"},
    "postmark": {"decl": "    int mark = 0;\n",
                 "pre": "", "post": "        mark = a;\n",
                 "tail": " + cq_measure(mark)"},
    "bodyread": {"decl": "    int mark = 0;\n    int acc = 0;\n",
                 "pre": "        mark = a;\n",
                 "post": "        acc = mark * 7;\n",
                 "tail": " + cq_measure(acc)"},
}

# The record axis is crossed with a DECLARED SUB-GRID, not with the whole 120.
# Reason, stated so nobody reads it as an oversight: a full 5x6x4x4 product is
# 480 cells and would quadruple a gate the whole suite already pays for, while
# the discriminating power of the extra cells is low — the round-1 reviewer's own
# 32-cell record run reached a TRACE COMPARISON in 6 cells and the rest were
# declines. The sub-grid keeps one cell of each PREFIX family that can relabel
# the rail (`none` control, `ry` non-diagonal, `add` dtzb in-place), both REGION
# kinds that matter for the uncompute spine (`eq` direct, `der` derived — the one
# that brings four template rails in), and the SUFFIX that moves the discharge
# point past the record (`none`, `ry`). 3 x 2 x 2 x 3 = 36 new cells.
RECORD_GRID_PREFIX = ("none", "ry", "add")
RECORD_GRID_REGION = ("eq", "der")
RECORD_GRID_SUFFIX = ("none", "ry")

# ── THE CONTROLLED-Ry-ARM AXIS ──────────────────────────────────────────────
# bd test_C_libtooling-drbq Inc 3 (drbq.4). See the module docstring's FIFTH AXIS
# paragraph for what this is for and what it is blind to. Three tables:
#
#   RY_REGION  — a region whose ARM rotates a SECOND register `r` with `cq_theta`
#                (Ry) while the CONDITION reads `a`. `r`'s physical wire is
#                disjoint from every condition wire, which is PRD §4 R4 and is
#                the whole accept shape. A cell here also carries `int r = 0;
#                r = cq_theta(r, 0.3);` in the head and `+ cq_measure(r)` in the
#                tail — those two lines appear in NO other cell in this file, by
#                construction, so the 156 pre-existing cells' source text is
#                byte-identical to what it was before this axis existed.
#   RGATE      — what stands on the ROTATED register `r`, inside the body,
#                outside the region. `none` is the shipped shape; it also leaves
#                `r`'s loop-carried φ an IDENTITY CARRY on every trip the arm does
#                not fire, which is the 8h7d.5 round-2 F-2 shape
#                (bd [`identity-carry-phi-does-not-refresh`]). `rypre`/`rypost`
#                are the non-diagonal in-place gate that REFRESHES it, on each
#                side of the region — and an off-chain forward Ry is itself a rail
#                gate (bd [`offchain-forward-ry-is-a-rail-gate`]), which is what
#                makes the position matter rather than just the presence.
#                `rzpost` is the DIAGONAL control (it must never move anything);
#                `addpost` is the dtzb in-place VALUE gate, same position,
#                different opcode family.
#   RECORD_R   — the RECORD axis moved off the condition register onto the
#                ROTATED one. Same three shapes, same reasons, same
#                declaration-hoisted-out-of-the-loop harness constraint.
RY_REGION = {
    "req": "        if (a == 5) { r = cq_theta(r, 0.9); }\n",
    # POLARITY. `clang -O1` canonicalizes `if (u != k)` to `icmp eq` with the
    # successors SWAPPED, so the gate arm is the FALSE successor and the emitter
    # must bracket the flag with `cqrt_x` (Rule 9). Not a re-spelling of `req`.
    "rne": "        if (a != 5) { r = cq_theta(r, 0.9); }\n",
    "req0": "        if (a == 0) { r = cq_theta(r, 0.9); }\n",
    # DERIVED condition — the one that brings the uncompute spine in with four
    # template rails between the mint and the strip.
    "rder": "        if (sqrt(a + 3.) <= 3.5) { r = cq_theta(r, 0.9); }\n",
    # TWO-SIDED: `clang -O1` emits `add %a, -6; icmp ult %t, 14`, so the condition
    # temp wears the dtzb IN-PLACE SHAPE on the condition rail (the OD-A oracle)
    # while the ARM relabels a different rail.
    "rrange": "        if (a > 5 && a < 20) { r = cq_theta(r, 0.9); }\n",
    # SEQUENTIAL pair in one body, both orders. Two `br` diamonds in a row lower
    # flat since bd hcrg; here one is an Rz region on the CONDITION register and
    # the other an Ry region on the ROTATED one, which is the first shape in this
    # file where two DIFFERENT rails are relabelled under two DIFFERENT flags in
    # one iteration. The order is an axis because the emission-ORDER fix (hcrg)
    # is what makes sequential regions legal at all.
    "rzry": ("        if (a == 5) { a = cq_phi(a, M_PI); }\n"
             "        if (a == 6) { r = cq_theta(r, 0.9); }\n"),
    "ryrz": ("        if (a == 5) { r = cq_theta(r, 0.9); }\n"
             "        if (a == 6) { a = cq_phi(a, M_PI); }\n"),
    # ── the two DECLINE CONTROLS. Singletons, deliberately not families. ──
    # R4: the Ry is on the CONDITION register's own wire, so the flag strip's
    # `icmp_..._unc` would recompute the compare against a RELABELLED register.
    # A permanent decline, in the loop and out of it; one cell is the whole
    # witness (the family lives in `control_inplace_ry_reject_cond_register.ll`).
    "rcond": "        if (a == 5) { a = cq_theta(a, 0.9); }\n",
    # SCOPED OUT of Inc 3: `clang -O1` never hands this to the pass as a diamond
    # — SimplifyCFG merges the two arms into ONE call with a `select` on the
    # ANGLE, which is bd drbq Inc 2b's by-difference shape, and the IN-LOOP form
    # of that is not this increment's. One cell, so that a future increment which
    # accidentally widens into it turns this table red.
    "rifelse": "        if (a == 5) { r = cq_theta(r, 0.9); }"
               " else { r = cq_theta(r, 0.3); }\n",
    # ── the OPAQUE-THRESHOLD family, and it is not decoration: it is this
    # axis's instance of the docstring's "ONE WAY THAT PROPERTY CAN BREAK
    # WITHOUT A COMPILER BUG", found by MEASURING the first regeneration rather
    # than by reading the tables (Rule 11).
    #
    # An Ry arm rotates a register the CONDITION does not read — that is the
    # accept shape (R4). The direct consequence is that `a` is LOOP-INVARIANT in
    # the body whenever no a-register gate stands beside the region, and a
    # literal-constant compare on a loop-invariant register is HOISTED: LICM
    # lifts it to the preheader on the ROLLED side, CSE merges the two
    # repetitions' compares on the UNROLLED side. Both then present the pass with
    # `compare … arm Ry on r … branch on that compare`, and the kjd1 gate-2c
    # window guard — which is NOT wire-aware, so a gate on a DISJOINT rail counts
    # — declines `condition predates a non-diagonal gate` on BOTH sides. Measured
    # at HEAD 1bdaa60 on `m_none_req_none_none_none`: 72 of the first 109 cells
    # came out inert that way, and an inert cell cannot witness Inc 3.
    #
    # Reading `off` (already `volatile`) as the compare's other operand defeats
    # both the hoist and the CSE without changing the tainted lineage by one
    # instruction, which is exactly the remedy the docstring prescribes. Measured
    # on the same binary: rolled declines `control flow inside a loop body`, flat
    # ACCEPTS — i.e. `UNROLLED-ONLY`, the live Inc-3 witness. The literal family
    # above is KEPT, in full: it is the shape a reader writes, its a-gated cells
    # are live on their own, and its inert cells now record the hoist decline.
    "oeq": "        if (a == off) { r = cq_theta(r, 0.9); }\n",
    "one": "        if (a != off) { r = cq_theta(r, 0.9); }\n",
    "oder": "        if (sqrt(a + 3.) <= (double)off)"
            " { r = cq_theta(r, 0.9); }\n",
}
RGATE = {
    "none": {"pre": "", "post": ""},
    "rypre": {"pre": "        r = cq_theta(r, 0.25);\n", "post": ""},
    "rypost": {"pre": "", "post": "        r = cq_theta(r, 0.25);\n"},
    "rzpost": {"pre": "", "post": "        r = cq_phi(r, 0.125);\n"},
    "addpost": {"pre": "", "post": "        r = r + off;\n"},
}
RECORD_R = {
    "rpremark": {"decl": "    int mark = 0;\n",
                 "pre": "        mark = r;\n", "post": "",
                 "tail": " + cq_measure(mark)"},
    "rpostmark": {"decl": "    int mark = 0;\n",
                  "pre": "", "post": "        mark = r;\n",
                  "tail": " + cq_measure(mark)"},
    "rbodyread": {"decl": "    int mark = 0;\n    int acc = 0;\n",
                  "pre": "        mark = r;\n",
                  "post": "        acc = mark * 7;\n",
                  "tail": " + cq_measure(acc)"},
}
RECORD_ALL = dict(RECORD, **RECORD_R)

# The sub-grids, declared rather than producted. Sizes are asserted in
# `cells_of_matrix` so a future edit cannot quietly change the cost of the gate.
# The split between the LITERAL and the OPAQUE region family is the one design
# decision here, and its whole reason is the `oeq`/`one`/`oder` comment above:
# a sub-grid that holds the a-register still must use an OPAQUE threshold or its
# cells are hoist-inert.
#
#   A1  the two literal core regions x the FULL a-register gate product      18
#   A2  every other literal region at an a-gate STAR (one gate at a time)    25
#   A3  the three OPAQUE regions at the same a-gate star                     15
#   B1  the second-register gate axis: opaque core x 4 gates x 2 a-shapes,
#       plus the literal core at the bare a-shape so the axis is witnessed
#       on the reader's spelling too                                         24
#   B2  every remaining region at the one second-register gate that refreshes 6
#   C   the RECORD axis on the ROTATED register (opaque, so it is live)      24
#   D   the RECORD axis on the CONDITION register while the arm rotates `r`   3
#   E   the two decline controls                                              2
RY_CORE_REGION = ("req", "rder")
RY_OTHER_REGION = ("rne", "req0", "rrange", "rzry", "ryrz")
RY_OPAQUE_REGION = ("oeq", "one", "oder")
RY_OPAQUE_CORE = ("oeq", "oder")
RY_DECLINE_REGION = ("rcond", "rifelse")
RY_A_GATES = ("none", "ry", "add")          # PREFIX and SUFFIX, on `a`
RY_A_STAR = (("none", "none"), ("ry", "none"), ("none", "ry"),
             ("add", "none"), ("none", "add"))
# B and C hold the a-register at `none` or at the dtzb VALUE gate. `ry` on `a`
# is deliberately absent from them: it is a non-diagonal gate on the CONDITION's
# own wire, which declines on both sides for a reason that has nothing to do with
# the second register these two sub-grids exist to move. It is covered — twice —
# by the A star.
RY_B_AGATES = (("none", "none"), ("none", "add"))
RY_C_SUFFIX = ("none", "add")

HDR = "#include <math.h>\nvolatile int off = 3;\n"

# TWO TRIPS, and two is not arbitrary: it is the smallest count at which the back
# edge is taken, so the "next activation" the window lemma reasons about actually
# exists in the trace, and it is small enough that a divergence is readable.
TRIPS = 2


def sources(prefix, region, suffix, record="none", rgate="none"):
    """(rolled, unrolled) C for one cell.

    THE SECOND REGISTER `r` APPEARS IF AND ONLY IF the region is an `RY_REGION`
    one, which is what makes the 156 pre-Inc-3 cells byte-identical to what they
    were before this axis existed (proven by diffing every generated source
    against the HEAD script, not asserted).
    """
    R = RECORD_ALL[record]
    G = RGATE[rgate]
    second = region in RY_REGION
    region_text = RY_REGION[region] if second else REGION[region]
    body = (PREFIX[prefix] + G["pre"] + R["pre"] + region_text + R["post"]
            + G["post"] + SUFFIX[suffix])
    head = ("int slice(void){\n    int a = 0;\n"
            + ("    int r = 0;\n" if second else "") + R["decl"]
            + "    a = cq_theta(a, 0.5);\n"
            + ("    r = cq_theta(r, 0.3);\n" if second else ""))
    tail = "    return cq_measure(a)%s%s;\n}\n" % (
        " + cq_measure(r)" if second else "", R["tail"])
    rolled = (
        HDR
        + head
        + "    for (int i = 0; i < %d; ++i) {\n" % TRIPS
        + body
        + "    }\n" + tail
        + "int main(void){(void)slice();return 0;}\n"
    )
    # The unrolled twin is the SAME TEXT, dedented one level and repeated — never
    # a re-spelling. A hand-written twin that differs in any other way would make
    # a trace divergence ambiguous between "the loop lowering is wrong" and "the
    # two programs are not the same program".
    flat = "".join(
        "    " + l[8:] if l.startswith(" " * 8) else l for l in body.splitlines(True)
    )
    unrolled = (
        HDR
        + head
        + flat * TRIPS
        + tail
        + "int main(void){(void)slice();return 0;}\n"
    )
    return rolled, unrolled


def _pair_check(path):
    """Run tools/free_pairing_check.py STRICT, in this interpreter."""
    import contextlib
    import io
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    import free_pairing_check
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            rc = free_pairing_check.main(["-q", path])
    except SystemExit as e:            # never today; a checker edit must not
        rc = e.code if isinstance(e.code, int) else 1   # turn into a silent pass.
    except Exception as e:             # ditto — an exception is a FAILURE here.
        return 1, "free_pairing_check raised %r\n%s" % (e, buf.getvalue())
    return rc, buf.getvalue()


class Side:
    """One compiled side of a cell."""

    def __init__(self):
        self.exit = None      # opt exit code
        self.diag = ""        # first `cq ...` diagnostic, or ""
        self.warns = 0        # stderr warning count
        self.trace = ""       # runtime trace, or ""
        self.error = None     # harness failure (clang/link/run), never a verdict


def _first_diag(text):
    for line in text.splitlines():
        i = line.find("cq ")
        if i >= 0:
            return line[i:].strip()
    return ""


def build_side(cfg, work, name, csrc):
    s = Side()
    cpath = os.path.join(work, name + ".c")
    with open(cpath, "w") as f:
        f.write(csrc)
    s1 = os.path.join(work, name + ".s1.ll")
    r = subprocess.run(
        [cfg.clang, "-I", cfg.include, "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
         cpath, "-o", s1],
        capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "stage 1 (clang -O1) failed:\n" + r.stderr
        return s
    s2 = os.path.join(work, name + ".s2.ll")
    r = subprocess.run(
        [cfg.opt, "-load-pass-plugin", cfg.plugin, "-passes=cq-lowering", "-S", s1,
         "-o", s2],
        capture_output=True, text=True)
    s.exit = r.returncode
    s.diag = _first_diag(r.stderr)
    s.warns = r.stderr.count("warning")
    if r.returncode != 0:
        return s
    # Stage 2b — STRICT. A cell that needs `--allow-unproven` is not a cell this
    # gate can speak for, and saying so loudly is the point.
    #
    # Called IN PROCESS, not as a subprocess: 240 python interpreter starts cost
    # ~70s of wall clock and the check itself ~0.02s. Safe here because cells run
    # in a PROCESS pool — `free_pairing_check` raises the interpreter's recursion
    # limit as a side effect, which is not something to do from several threads of
    # one interpreter.
    rc, out = _pair_check(s2)
    if rc != 0:
        s.error = "stage 2b (free_pairing_check, STRICT) failed:\n" + out
        return s
    exe = os.path.join(work, name + ".exe")
    # Stage 3, SPLIT (bd dgn5, the same trick `run_slice.sh` uses and for the same
    # reason): the clang DRIVER dlopens libLTO -> libLLVM (140MB) on every -O0
    # link that never uses LTO, MEASURED at ~1.0s per cell, i.e. 200s of CPU for
    # this gate alone. `$CQ_LD` is the wrapper CMake derives from this same clang
    # via `clang -###` with `-lto_library` removed; unset (by-hand invocation) the
    # driver runs and is exactly equivalent, only slower.
    if cfg.ld and os.access(cfg.ld, os.X_OK):
        obj = os.path.join(work, name + ".o")
        r = subprocess.run([cfg.clang, "-c", s2, "-o", obj],
                           capture_output=True, text=True)
        if r.returncode == 0:
            r = subprocess.run([cfg.ld, "-o", exe, obj, cfg.templates, cfg.runtime],
                               capture_output=True, text=True)
    else:
        r = subprocess.run([cfg.clang, s2, cfg.templates, cfg.runtime, "-o", exe],
                           capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "stage 3 (link) failed:\n" + r.stderr
        return s
    r = subprocess.run([exe], capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "stage 4 (run) exited %d" % r.returncode
        return s
    s.trace = r.stdout
    return s


def counts(trace):
    return (trace.count("_unc("), trace.count("cqrt_free("), trace.count("-> h"))


def cell_name(cell):
    """THREE grammars, and the arity is what tells them apart — deliberately, so
    that adding an axis can never rename a committed cell:

      `m_<prefix>_<region>_<suffix>`                    the 120 record-free cells
      `m_<prefix>_<region>_<suffix>_<record>`           the 36 RECORD cells
      `m_<prefix>_<region>_<suffix>_<record>_<rgate>`   the 117 Ry-ARM cells

    The Ry cells ALWAYS carry all five segments (`..._none_none` included) and
    their region token is always an `RY_REGION` one, so no name can collide with
    a shorter grammar's. All three keep the `m_` prefix, so `grep -c '^m_'` still
    counts cells.
    """
    prefix, region, suffix, record, rgate = cell
    if region in RY_REGION:
        return "m_%s_%s_%s_%s_%s" % cell
    if record == "none":
        return "m_%s_%s_%s" % (prefix, region, suffix)
    return "m_%s_%s_%s_%s" % (prefix, region, suffix, record)


def ry_cells():
    """The controlled-Ry-arm sub-grids (bd drbq Inc 3). See `RY_*` above."""
    out = []
    # A1 — the two literal core regions, FULL a-register gate product.
    out += [(p, g, s, "none", "none") for p, g, s
            in itertools.product(RY_A_GATES, RY_CORE_REGION, RY_A_GATES)]
    # A2 — every other literal region at the a-gate STAR (one gate at a time).
    out += [(p, g, s, "none", "none")
            for g in RY_OTHER_REGION for p, s in RY_A_STAR]
    # A3 — the OPAQUE regions at the same star.
    out += [(p, g, s, "none", "none")
            for g in RY_OPAQUE_REGION for p, s in RY_A_STAR]
    # B1 — the second-register gate axis.
    out += [(p, g, s, "none", rg)
            for g in RY_OPAQUE_CORE
            for rg in RGATE if rg != "none"
            for p, s in RY_B_AGATES]
    out += [("none", g, "none", "none", rg)
            for g in RY_CORE_REGION
            for rg in RGATE if rg != "none"]
    # B2 — every remaining region at the one second-register gate that refreshes.
    out += [("none", g, "none", "none", "rypost")
            for g in RY_OTHER_REGION + ("one",)]
    # C — the RECORD axis on the ROTATED register.
    out += [("none", g, s, k, rg)
            for g in RY_OPAQUE_CORE
            for s in RY_C_SUFFIX
            for k in RECORD_R
            for rg in ("none", "rypost")]
    # D — the RECORD axis on the CONDITION register while the arm rotates `r`.
    out += [("none", "oeq", "none", k, "none")
            for k in RECORD if k != "none"]
    # E — the two decline controls.
    out += [("none", g, "none", "none", "none") for g in RY_DECLINE_REGION]
    return out


def cells_of_matrix():
    """The full cell list: the 120-cell PREFIX x REGION x SUFFIX product with no
    record, plus the 36-cell record sub-grid (see `RECORD_GRID_*`), plus the
    117-cell controlled-Ry-arm sub-grids (see `RY_*`). 273 cells.

    The sizes are ASSERTED, not commented: this gate costs ~2 minutes of the
    suite's ~130-230s band and an axis edit that silently doubles it should stop
    the run, not surprise the next person to time it.
    """
    base = [(p, r, s, "none", "none") for p, r, s
            in itertools.product(PREFIX, REGION, SUFFIX)]
    rec = [(p, r, s, k, "none") for p, r, s, k
           in itertools.product(RECORD_GRID_PREFIX, RECORD_GRID_REGION,
                                RECORD_GRID_SUFFIX,
                                [k for k in RECORD if k != "none"])]
    ry = ry_cells()
    assert (len(base), len(rec), len(ry)) == (120, 36, 117), \
        "sub-grid sizes moved: %d/%d/%d" % (len(base), len(rec), len(ry))
    cells = base + rec + ry
    names = [cell_name(c) for c in cells]
    assert len(set(names)) == len(names), "duplicate cell name"
    return cells


def run_cell(cfg, cell):
    prefix, region, suffix, record, rgate = cell
    name = cell_name(cell)
    rolled_src, unrolled_src = sources(prefix, region, suffix, record, rgate)
    work = tempfile.mkdtemp(prefix="cqtwin_")
    try:
        rolled = build_side(cfg, work, name, rolled_src)
        unrolled = build_side(cfg, work, name + "_u", unrolled_src)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return name, rolled, unrolled


def _run_cell_star(arg):
    return run_cell(*arg)


def verdict(name, rolled, unrolled):
    """(verdict-string, failure-report-or-None).

    The verdict is what the committed table stores; the report is a hard failure
    that no table entry can bless (a harness break, or a divergence).
    """
    if rolled.error:
        return "HARNESS-ERROR", "%s: rolled side: %s" % (name, rolled.error)
    if unrolled.error:
        return "HARNESS-ERROR", "%s: unrolled side: %s" % (name, unrolled.error)

    if rolled.exit == 0 and unrolled.exit == 0:
        if rolled.trace != unrolled.trace:
            # (ii) TRACE DIVERGENCE — always a hard failure, never blessable.
            rl, ul = rolled.trace.splitlines(), unrolled.trace.splitlines()
            first = next((i for i in range(max(len(rl), len(ul)))
                          if i >= len(rl) or i >= len(ul) or rl[i] != ul[i]), 0)
            rep = ["%s: ROLLED AND UNROLLED TRACES DIFFER (this is the F-4 class)" % name,
                   "  first differing line %d:" % (first + 1),
                   "    rolled   : %s" % (rl[first] if first < len(rl) else "<end>"),
                   "    unrolled : %s" % (ul[first] if first < len(ul) else "<end>"),
                   "  counts (_unc, cqrt_free, handle mints):",
                   "    rolled   : %s over %d lines" % (counts(rolled.trace), len(rl)),
                   "    unrolled : %s over %d lines" % (counts(unrolled.trace), len(ul))]
            return "TRACE-DIVERGENCE", "\n".join(rep)
        if rolled.warns > unrolled.warns:
            # (iii) ASYMMETRIC DIAGNOSTIC — the rolled form complaining where its
            # twin does not is a compiler asymmetry even when the traces agree.
            return "WARN-ASYMMETRY", (
                "%s: rolled side emits %d warning(s), its twin %d — a compiler "
                "asymmetry, not a property of the program:\n    %s"
                % (name, rolled.warns, unrolled.warns, rolled.diag))
        if rolled.warns or unrolled.warns:
            return "ACCEPT-IDENTICAL-WARN\t%s" % rolled.diag, None
        return "ACCEPT-IDENTICAL", None

    if rolled.exit != 0 and unrolled.exit != 0:
        if rolled.diag == unrolled.diag:
            return "DECLINE-BOTH\t%s" % rolled.diag, None
        return "DECLINE-BOTH-DIFFERENT\t%s\t%s" % (rolled.diag, unrolled.diag), None

    # (i) DISPOSITION MISMATCH. Recorded as a VERDICT rather than an unconditional
    # failure, because `clang -O1` canonicalizes the two spellings differently and
    # a couple of cells legitimately land on opposite sides of a shipped decline
    # (see the table's own notes). A NEW one still turns the table red.
    if rolled.exit == 0:
        return "ROLLED-ONLY\t%s" % unrolled.diag, None
    return "UNROLLED-ONLY\t%s" % rolled.diag, None


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--clang", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--include", required=True)
    ap.add_argument("--runtime", required=True)
    ap.add_argument("--templates", required=True)
    ap.add_argument("--expected",
                    default=os.path.join(HERE, "loop_twin_matrix.expected.txt"))
    ap.add_argument("--ld", default=os.environ.get("CQ_LD", ""),
                    help="the bd dgn5 link wrapper (CMake exports it as CQ_LD); "
                         "empty falls back to the clang driver")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--regenerate", action="store_true",
                    help="rewrite the expected table from this run. DELIBERATE "
                         "ONLY — say which cells moved and why (Rule 12).")
    cfg = ap.parse_args()

    cells = cells_of_matrix()
    results = {}
    # A PROCESS pool, not a thread pool — stage 2b runs in-process (see
    # `_pair_check`) and mutates the interpreter's recursion limit.
    with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
        for name, rolled, unrolled in ex.map(_run_cell_star,
                                             [(cfg, c) for c in cells]):
            results[name] = (rolled, unrolled)

    got, hard = {}, []
    for name in sorted(results):
        v, report = verdict(name, *results[name])
        got[name] = v
        if report:
            hard.append(report)

    if cfg.regenerate:
        with open(cfg.expected, "w") as f:
            f.write(EXPECTED_HEADER)
            for name in sorted(got):
                f.write("%-24s %s\n" % (name, got[name]))
        print("regenerated %s (%d cells)" % (cfg.expected, len(got)))
        if hard:
            print("\nREGENERATION REFUSED TO HIDE %d HARD FAILURE(S):" % len(hard))
            for r in hard:
                print(r)
            return 1
        return 0

    want = {}
    with open(cfg.expected) as f:
        for line in f:
            line = line.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            name, _, v = line.partition(" ")
            want[name] = v.strip()

    fails = list(hard)
    for name in sorted(set(got) | set(want)):
        if name not in want:
            fails.append("%s: NEW CELL, not in the expected table" % name)
        elif name not in got:
            fails.append("%s: MISSING — the expected table has it, this run did not"
                         % name)
        elif got[name] != want[name]:
            fails.append("%s: verdict changed\n    expected: %s\n    got     : %s"
                         % (name, want[name], got[name]))

    accepts = sum(1 for v in got.values() if v.startswith("ACCEPT-IDENTICAL"))
    declines = sum(1 for v in got.values() if v.startswith("DECLINE"))
    print("loop_twin_matrix: %d cells — %d ACCEPT-IDENTICAL, %d DECLINE, %d other"
          % (len(got), accepts, declines, len(got) - accepts - declines))
    if fails:
        print("\nFAILED (%d):" % len(fails))
        for r in fails:
            print(r)
            print()
        return 1
    print("all cells match tools/loop_twin_matrix.expected.txt")
    return 0


EXPECTED_HEADER = """\
# loop_twin_matrix.expected.txt — the committed disposition table for
# tools/loop_twin_matrix.py (bd test_C_libtooling-8h7d.5, Rule-13 round 4).
#
# ONE LINE PER CELL, `m_<prefix>_<region>_<suffix>` — plus a fourth `_<record>`
# segment on the 36 RECORD-axis cells (bd drbq Inc 2a round-1 review), plus a
# fifth `_<rgate>` segment on the 117 CONTROLLED-Ry-ARM cells (bd drbq Inc 3,
# whose region token always starts `r`) — then its
# verdict. A name longer than the 24-column pad simply runs past it and is still
# separated from its verdict by exactly one space; the pad was deliberately NOT
# widened, because widening it would have rewritten all 156 pre-Inc-3 rows for a
# cosmetic reason and this file is a diff-read artifact. The gate
# fails on ANY deviation, in either direction: a cell that starts declining, a
# cell that starts accepting, and a cell whose decline message changes owner are
# all reds. That is the point — a disposition drift in the loop lowering must
# never be something a reader has to notice.
#
# VERDICTS
#   ACCEPT-IDENTICAL        both sides lower, both silent, traces byte-identical.
#   ACCEPT-IDENTICAL-WARN   as above but both sides warn, with the same message.
#   DECLINE-BOTH            both sides decline with the SAME diagnostic.
#   DECLINE-BOTH-DIFFERENT  both decline, different diagnostics.
#   ROLLED-ONLY / UNROLLED-ONLY
#                           a DISPOSITION MISMATCH: one side lowers, the other
#                           declines with the recorded message. Every such cell
#                           needs a written reason — today's THREE are all the
#                           same `clang -O1` canonicalization artifact of the
#                           UNROLLED spelling, and all three are `xor`/`none`
#                           (prefix `a = a ^ 9;`, no suffix): flattening puts one
#                           repetition's `xor` immediately before the next one's
#                           region, clang folds it in, and the arm becomes a mixed
#                           phase/value arm that does not exist in the rolled
#                           form. Not a compiler asymmetry — the two sides stopped
#                           being the same program shape. `m_xor_range_none` was
#                           added with the `range` axis (bd 8h7d.5 round-5
#                           cleanup) and is the third member of that one family,
#                           not a new phenomenon.
#
# THE 18 `UNROLLED-ONLY` RECORD CELLS — every one with SUFFIX `ry` — AND WHY THEY
# ARE THE FENCE WORKING, WRITTEN OUT BECAUSE THE TABLE DEMANDS A REASON PER
# MISMATCH (bd drbq Inc 2a round-1 review, the record axis).
#   ROLLED side: the record (`mark`, or `acc`'s source) is defined in the body and
#     read either after the loop or on a later activation, and the SUFFIX
#     `a = cq_theta(a, -0.5)` is a NON-DIAGONAL in-place gate on the same rail
#     between the definition and the read. That is the 8h7d.5 F-1/F-2 staleness
#     exactly, and `LoopLowering::staleRailRecordRead` declines it
#     (`cq loop lowering: rail record read past an in-place gate on the same
#     rail`; the three `bodyread` cells reach `declineStaleRecordOps` first and
#     decline as `cq opcode lowering: operand predates a non-diagonal gate`).
#     Correct, and the whole reason that fence exists.
#   UNROLLED side: it ACCEPTS, and it emits `cqrt_measure_i32(%h)` for the
#     record — i.e. it measures the register at its POST-Ry value. ⚠ THAT IS A
#     PRE-EXISTING PROPERTY OF THE STRAIGHT-LINE PATH, NOT OF THE LOOP LOWERING
#     AND NOT OF THIS INCREMENT. Measured on BOTH the pre-2a (`f92d95e`) and the
#     post-2a binary, byte-identically, on the matrix cells and on the minimal
#     probe `int mark = a; a = cq_theta(a, 0.25); return cq_measure(mark);`
#     (rc 0, no warning, both binaries). The loop half of this class is fenced
#     (8h7d.5 round 1 / round 2 F-1); the straight-line half is not, and whether
#     it should be is an OPEN question for the owner — under Rule 8 `int mark = a`
#     is an ALIAS of one register, so measuring the current register may be the
#     only thing physically available, in which case the right answer is a loud
#     decline rather than a different unitary. Filed as an observation, NOT fixed
#     here: nothing in this increment moves it, in either direction.
#   So these cells are recorded as `UNROLLED-ONLY`, and a change in EITHER
#   direction is a red — the rolled side starting to accept, or the unrolled side
#   starting to decline, both need a written decision.
#
# THE 117 CONTROLLED-Ry-ARM CELLS (bd test_C_libtooling-drbq Inc 3, drbq.4) AND
# WHY HALF OF THEM ARE `UNROLLED-ONLY` TODAY — THIS IS THE POINT OF THE AXIS, NOT
# A DEFECT IN IT. This table was regenerated at HEAD 1bdaa60, BEFORE the Inc-3
# lowering exists. The flat (unrolled) form of an Ry arm on a second, disjoint
# register lowers CONTROL-IN-PLACE since drbq Inc 1
# (`cqrt_ry_<W>_controlled`); the ROLLED form declines
# `cq controlled lowering: control flow inside a loop body under quantum control`
# (control-in-place-PRD §4 R7, fixture
# `ir-pass/test/control_inplace_ry_reject_in_loop.ll`). So the expected
# disposition of a well-formed cell here is UNROLLED-ONLY with that exact
# message, and Inc 3's job is to flip those rows to ACCEPT-IDENTICAL.
#
# MEASURED COMPOSITION AT 1bdaa60, so the next reader can diff a count and not
# just rows. 77 of the 117 have the ROLLED side declining on the loop message —
# 59 `UNROLLED-ONLY` (flat accepts: the cells Inc 3 must flip to
# ACCEPT-IDENTICAL) and 18 `DECLINE-BOTH-DIFFERENT` (flat declines for its own
# reason: 9 on the hoisted-condition guard below, 8 on R6's
# `stale rail record read past a controlled Ry`, 1 on the Inc-2b
# `rotation angle`). The remaining 40 decline on BOTH sides with the SAME
# message, which is the reassuring direction — the two spellings agree — and they
# are the cells Inc 3 will NOT flip by lifting R7 alone:
#   31  `condition predates a non-diagonal gate` — 16 are the LOOP-INVARIANT
#       CONDITION family (literal-constant compare + no a-register gate ⇒ LICM
#       hoists it out of the loop, CSE merges the flat twin's two copies, and the
#       kjd1 gate-2c window guard, which is not wire-aware, counts the arm's Ry on
#       the DISJOINT rail `r` as an intervening gate). The other 15 carry an
#       `a = cq_theta(a, …)` PREFIX or SUFFIX, i.e. a genuine non-diagonal gate on
#       the condition's own wire. ⚠ THE FIRST FAMILY IS THE ONE TO READ: it says
#       that lifting the R7 loop fence does not by itself make
#       `for (…) { if (a == 5) r = cq_theta(r, .9); }` compile. The `oeq`/`one`/
#       `oder` regions exist so that the same shape with an OPAQUE threshold is
#       still a live witness.
#       ⚠ AND DO NOT READ THIS STRING AS A FENCE NAME. `ArmClassify`'s
#       `declineArm` lambda RE-SPELLS every later decline with this same text
#       whenever the condition wire carries a provably-post-region non-diagonal
#       gate, so for the 15 a-theta cells the printed message may be a re-spelling
#       of a different refusal. It was verified to be the gate-2c window guard
#       itself only for the 16 loop-invariant cells, where no gate stands on the
#       condition wire at all and there is nothing to re-spell. Anyone reading
#       these rows to plan Inc 3 must confirm the owning fence in the source, not
#       from the string.
#    8  `cq opcode lowering: operand predates a non-diagonal gate` — the
#       `rbodyread` record shape (`acc = mark * 7`), caught by the pass-wide
#       `declineStaleRecordOps` before either control fence sees it.
#    1  `m_none_rcond_none_none_none`, the R4 decline control.
#
#   READ THE DIFF, NOT THE ROWS. When Inc 3 lands, a row that flips
#   UNROLLED-ONLY -> ACCEPT-IDENTICAL is the increment working. A row that flips
#   to TRACE-DIVERGENCE cannot appear here at all (it is a hard failure), and a
#   row that flips to DECLINE-BOTH means the FLAT lowering regressed, which is an
#   Inc-1 regression wearing an Inc-3 row. A `DECLINE-BOTH-DIFFERENT` row whose
#   ROLLED half is the loop message should converge to `DECLINE-BOTH` on the
#   UNROLLED half's message — if instead it becomes `ROLLED-ONLY`, the rolled
#   side has started accepting something its own flat twin refuses, which is an
#   over-accept and a Prime-Directive red however green the run looks.
#
#   A ROLLED DIAGNOSTIC OTHER THAN THE LOOP MESSAGE IS INFORMATION, NOT NOISE: it
#   means that cell's rolled side declines for a reason that is NOT the loop, so
#   lifting the loop fence alone will not flip it. The four owning fences are
#   named in the composition above.
#
#   The two singleton DECLINE CONTROLS are expected to stay put across Inc 3:
#   `m_none_rcond_none_none_none` puts the Ry on the CONDITION register's own
#   wire (PRD §4 R4 — a permanent decline; note its message is the GENERIC
#   `control flow under quantum control`, not an R4-specific one, so a future
#   R4 message change moves this row), and `m_none_rifelse_none_none_none` is the
#   drbq Inc 2b angle-select shape, scoped OUT of Inc 3.
#
# TRACE-DIVERGENCE and WARN-ASYMMETRY are NEVER recorded here. They are hard
# failures whatever this file says — a trace that differs from its twin's is the
# defect this gate exists to catch, and no table entry may bless it.
#
# REGENERATE DELIBERATELY: `--regenerate`, then state in the commit message which
# cells moved and why (Rule 12). Regeneration will not overwrite a hard failure.
"""


if __name__ == "__main__":
    sys.exit(main())
