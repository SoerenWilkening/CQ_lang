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

AND THE QUARANTINE, `tools/loop_twin_matrix.quarantine.txt` (bd
test_C_libtooling-drbq Inc 3, round-1 lens L7). A QUARANTINE IS NOT A BLESSING.
A divergence may still never be recorded as an expected VERDICT — that would
retire this gate — so a cell holding a FILED, root-caused, bd-tracked defect is
moved OUT of the expected table and pinned in the quarantine to the EXACT
unified-diff signature of its divergence. It then passes ONLY while it diverges
in exactly that way, and it FAILS in both directions: if the signature moves, if
the cell stops diverging ("quarantine stale — remove it"), if the cell appears in
both files, or if any NON-quarantined cell diverges. The alternative that was
rejected is worth naming: leaving the gate permanently red, which is Rule 19's
own argument in reverse — a gate expected to be red is a gate people stop
reading, and the F-4 class above was found BECAUSE the gate was green and one
cell went red. Two BOUNDARY CONTROLS (`QUARANTINE_CONTROLS`) run beside the cells
on every invocation — `--regenerate` and `--refresh-quarantine` included, and
each of those REFUSES TO WRITE while a control has moved — and make the
quarantine's class story a measurement rather than a paragraph.

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
with the record on `a` while the arm rotates `r`; two singleton DECLINE
controls; and the drbq-Inc-4 CONTROLLED STATE-PREP decline control. 118 cells.

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

THE SIXTH AXIS — THE `cq_phi` SURFACE (`--phi-surface`, bd
test_C_libtooling-3qlq Increment 1, "retire the swap route"). NOT a cell axis:
a whole-matrix MODE, because it changes the FRONTEND, not the program shape.

    void      (SHIPPED)  `cq_phi(T);`         the Increment-1 branch phase
    register  (RETIRED)  `a = cq_phi(a, T)`   the pre-3qlq 15-width per-register Rz

`void` IS THE SURFACE THE GATE RUNS. `e2e-loop-twin-matrix` passes
`--phi-surface void` and `include/CQ.h` declares `void cq_phi(double angle)`;
`register` survives only as an argparse default so that a by-hand invocation
written before Increment 1 keeps its meaning, and it is UNREACHABLE against the
shipped header. Each surface owns ITS OWN table pair (`SURFACE_TABLES`): the
void one took the live names, the register one is `.register.txt` with its
content byte-unchanged, and no file is ever read as a measurement of a surface
it was not measured on.

THE HEADER GUARD RUNS ON EVERY INVOCATION AND IN BOTH DIRECTIONS: the surface a
run generates and the surface `--include-dir`'s CQ.h declares must agree, or
every cell fails at stage 1 and the wall of clang errors reads like a wall of
lowering declines. Both halves of that were measured defects (round-1 review
finding F-L5-7): `void` used to test the LITERAL substring `"void cq_phi(double"`
and so refused the shipped header, whose declaration is column-aligned; and
`register` was never asked at all, so the committed ctest invocation produced
175 HARNESS-ERRORs plus 172 "verdict changed" instead of one line naming the
surface it had been handed. The question is now asked by
`phi_surface_of_header`, a pure function over the header text with C comments
stripped, which `loop_twin_matrix_quarantine_test.py` exercises against the REAL
`include/CQ.h` — a guard exercised only against the stand-in it was written
beside is a guard that has not been tested.

WHAT EACH AXIS MEANS UNDER `void`, WRITTEN OUT BECAUSE THREE OF THEM CHANGE
MEANING AND ONE GOES VACUOUS:

  * THE REGION CELLS BECOME KICKBACK CELLS. `if (a == 5) { cq_phi(M_PI); }` puts
    the phase on the BRANCH, not on the register: PRD §3 mints the flag, fires
    ONE UNCONTROLLED `cqrt_rz_i1(f, T)` on it, strips with the ordinary compare
    `_unc` and frees. NO GATE LANDS ON `a` AT ALL. The rolled-vs-unrolled twin
    question is unchanged and still the whole point — both spellings are still
    the same program — but what it is comparing is now a flag stream, not a
    register relabelling.

  * THE `RECORD` AXIS IS VACUOUS FOR AN Rz REGION, AND SAYING SO IS THE POINT.
    `premark` / `postmark` / `bodyread` exist to pin the 8h7d.5 F-1 / F-3
    staleness class: `int mark = a;` read at a position where the register no
    longer holds it. Under `register` an Rz arm at least DEFINED a new SSA name
    for `a` (diagonal, so `staleRailRecordRead` exempted it, but the def existed
    and the chain ran through it). Under `void` there is no def and no chain hop:
    across an Rz REGION a record cannot be stale, by construction. Those cells
    still witness the PREFIX/SUFFIX gates (`ry`, `add`, `xor`) that CAN relabel
    `a` — that is why they are kept, not deleted — but a `void` run must NOT be
    quoted as covering "a record read across a phase arm". There is no longer
    such a thing to read across.

  * THE `rz` PREFIX / `rz` SUFFIX / `rzpost` RGATE VALUES COLLAPSE ONTO `none`.
    An UNCONTROLLED `cq_phi(T)` is a global phase and Increment 1 DELETES it
    (PRD D2), so after Inc 1 those three axis values emit nothing and the cells
    are duplicates of their `none` siblings modulo a deleted line. They are kept
    for exactly one reason: a `void` run in which an `rz`-prefixed cell differs
    from its `none` sibling means the deletion did not happen or did not happen
    everywhere, which is the only cheap witness for D2 this file can carry.

  * THE Ry-ARM CELLS (`RY_REGION`, `RGATE`, `RECORD_R`) ARE UNCHANGED. `cq_theta`
    keeps `a = cq_theta(a, T)` (PRD D5); nothing on that axis touches `cq_phi`
    except the `rzpost` RGATE and the `rzry`/`ryrz` sequential pairs, whose Rz
    half becomes a kickback exactly as above.

  * `ifelse` UNDER `void` IS THE Rz ANGLE SELECT. `-O1` folds it to ONE call on
    `select i1 %c, double A, double B` (MEASURED), which PRD §3 lowers to the
    EXACT two-gate form `x(f); rz_i1(f,B); x(f); rz_i1(f,A)` — no subtraction, no
    2^-40 rounding fence, run-time arms admitted. The Ry stem keeps the 2b
    by-difference form. So the two stems' angle selects are DIFFERENT lowerings
    after Inc 1, by design; this file only ever compares a cell against ITSELF
    rolled/unrolled, so that split costs it nothing — but do not carry the
    `ifelse` row across to a cross-stem instrument and expect one gate line.

A `void` RUN IS AN ORDINARY RUN OF THIS GATE. It reads and writes ITS OWN
expected table and quarantine, with the same semantics in both directions and
the same two deliberate write modes. That is a CHANGE, and the reason for the
change is worth more than the change: while `register` was the shipped surface
and the only tables on disk were its, a void run correctly consulted neither —
both artefacts held register-surface measurements and neither claim survived the
surface change, so a void run measured, printed and returned. Once `void` BECAME
the shipped surface that arrangement inverted into a defect: a gate whose
expected table is "none" pins nothing, so a cell may change disposition run to
run with no red anywhere, which is precisely what this table exists to stop
(Rule 12; the 8h7d.5 F-4 argument above). Two files per surface, one code path.

THE QUARANTINE'S TWO CLAIMS SPLIT ACROSS THE SURFACE CHANGE, and that split is
why the void quarantine is a NEW FILE rather than the old one carried over. Its
CLAIM — "this cell holds a FILED, root-caused defect: bd test_C_libtooling-1m5p
class A, bd test_C_libtooling-a3z7 class B" — is about `Uncomputation` /
`FreePoint` interior placement and `ArithLowering` M-C, neither of which has
anything to do with `cq_phi`; that is surface-INDEPENDENT and carries over
verbatim. Its SIGNATURE is a SHA-256 digest of a TRACE, and a register-surface
trace says nothing about a void one; every void signature is therefore
re-measured on the void surface, and a cell is in the void quarantine only
because it was measured diverging THERE.

THE ONE THING THE VOID SURFACE COSTS THIS FILE is the second boundary control —
see `SURFACE_CONTROL_VERDICTS`. `q_armoncond` isolates "the divergence needs an
arm OFF the condition register" by putting the arm back ON it, and a branch phase
reads no register by construction, so that isolation is not expressible here and
no substitute exists (the only void gate that writes a register is `cq_theta`,
and an in-place Ry arm on the condition's own wire is itself a loud decline).
Both controls are still a GATE — their exact verdicts are PINNED and any change
is a red — but on the void surface the quarantine's class story is bounded by
`q_noregion` (whose two sources contain no `cq_phi` at all and are byte-identical
on both surfaces) plus the per-cell signatures, and NOT by `q_armoncond`.

ONE NEW SIDE STATE EXISTS ONLY UNDER `void`, AND IT IS A DISPOSITION RATHER THAN
A HARNESS BREAK. A binary that predates Increment 1 has no concept of
`void @cq_phi(double)`: it neither lowers nor deletes the call, which therefore
SURVIVES into the lowered IR and cannot link (there is no such runtime symbol,
and this epic adds none — PRD D3). MEASURED on the pre-3qlq oracle 52d7764:
`cq_phi(0.125);` uncontrolled leaves `tail call void @cq_phi(double 1.25e-01)`
in the output at exit 0. The side is recorded `PHI-UNLOWERED` and stages 2b/3/4
are skipped for it; calling that a link failure would file the pre-increment
disposition as a harness error. After Increment 1 the verdict must not appear.
"""

import argparse
import concurrent.futures
import difflib
import hashlib
import itertools
import os
import re
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
    # ── the CONTROLLED STATE-PREP decline control (bd
    # test_C_libtooling-drbq Inc 4 / drbq.5). ONE cell, added BEFORE any
    # Inc-4 lowering exists, for the same reason the whole Ry axis was
    # (`--regenerate`d at 1bdaa60 before Inc 3): a table written after the
    # implementation can only say the implementation agrees with itself.
    #
    # The arm's `cq_theta` has a CLASSICAL arg-0, so it mints a FRESH rail
    # rather than relabelling `r` — PRD §4 R1's "classical seed — controlled
    # state prep, Inc 4" bail (`ArmClassify.cpp:725`). Inc 4 lifts that bail
    # for the FLAT diamond and this cell is the assertion that it does not
    # follow `r` into a loop.
    #
    # ⚠ WHAT THIS CELL CANNOT TELL YOU, said plainly because it declines for
    # TWO independent reasons and a control that does should say so. The
    # wrapper seeds `r = cq_theta(r, 0.3)` before the loop on every
    # `RY_REGION` cell, so the merge phi's pred-edge incoming here is the
    # loop-carried QUANTUM `r`, never a constant — which makes the region a
    # genuine Q data mux (a fresh prepped rail on one edge, a live handle on
    # the other) INDEPENDENTLY of the loop. MEASURED at ORACLE b506b3b: the
    # rolled side declines `control flow`, the flat twin declines `condition
    # predates a non-diagonal gate` — and the flat twin is a two-region
    # sequence whose SECOND region's pred incoming is the FIRST region's
    # merge phi, i.e. a mux for the same reason one hop along. So a red here
    # means "Inc 4 widened into a loop OR into a non-constant pred incoming";
    # it does not isolate which. The isolating flat cells are the lit family,
    # not this file.
    "rprep": "        if (a == 5) { r = cq_theta(0, 0.9); }\n",
    # ── SUB-GRID F: THE MIXED LOOP (bd 3qlq Inc 1, the Rule-13 CLEARANCE
    # finding C-1, the BLOCK). The clearance's §4 (ii) note is the reason these
    # exist: "the C-1 mixed-loop shape has neither a fixture nor a twin gate nor
    # a matrix axis", and 274 cells could not see it because NOTHING in this file
    # put a loop-INVARIANT condition register beside a loop-CARRIED second one.
    #
    # Every RY_REGION spelling above builds its condition from `a` and its ARM
    # from `r`; that makes `a` invariant, but the condition is then a compare on
    # an invariant register, which LICM either hoists (the literal family, inert)
    # or is defeated by `off` (the opaque family). D4's per-bit idiom is the third
    # thing: the condition is DERIVED PER TRIP from an invariant register
    # (`(a >> i) & 1`), so it is loop-VARIANT while `a` is not — it mints a fresh
    # `cq_template_and_i32_hl` rail every iteration that must be discharged every
    # iteration. Add a per-trip gate on `r` and `collapseRailPhisIn` returns
    # `Collapsed`, which is exactly the dispatch C-1 lived in.
    #
    # THE ARM IS WRITTEN AS A PHASE ON `r` so that BOTH surfaces are a sensible
    # program: under `void` it rewrites to the bare `cq_phi(0.2);` — D4's kickback
    # with `a` invariant — and on the `register` surface it is
    # `r = cq_phi(r, 0.2)`, the old-surface twin the pre-3qlq oracle compiled
    # (`clearance_c1`'s `d1o`). An arm spelled `a = cq_phi(a, ...)` would write
    # `a` on the register surface and destroy the invariance the sub-grid is about
    # — the same trap `SURFACE_CONTROL_VERDICTS` records for `q_armoncond`.
    #
    # THE `d` VARIANTS ADD A POST-LOOP DIFFUSION on `a` (`POSTLOOP_FOR_REGION`).
    # It is what turns a leaked per-bit rail from a Rule-6 leak into a WRONG
    # UNITARY (the leaked rails are which-path records of `a`'s bits and the
    # diffusion interferes branches carrying distinct labels, Rule 8), so the
    # axis carries it and its absence as two separate columns.
    "pbit": "        if ((a >> i) & 1) { r = cq_phi(r, 0.2); }\n",
    "pbitd": "        if ((a >> i) & 1) { r = cq_phi(r, 0.2); }\n",
    # POLARITY (Rule 9): `clang -O1` canonicalizes the zero test to `icmp eq`
    # with the successors swapped, so the arm is the FALSE successor and the
    # emitter must bracket the flag with `cqrt_x`.
    "pbitne": "        if (((a >> i) & 1) == 0) { r = cq_phi(r, 0.2); }\n",
    "pbitned": "        if (((a >> i) & 1) == 0) { r = cq_phi(r, 0.2); }\n",
}

# The regions whose body reads the LOOP INDEX. The hand-unrolled twin has no
# `for`, so `_wrap` must bind `i` itself for these and only these — see
# `_wrap`'s `index` parameter. Keyed by region name so the existing 274 cells
# take the `False` path and stay byte-identical.
INDEXED_REGION = ("pbit", "pbitd", "pbitne", "pbitned")

# A line emitted AFTER the loop (and after the flat repetitions), before the
# `return`. Empty for every pre-C-1 region, which is what keeps their generated
# sources byte-unchanged.
POSTLOOP_FOR_REGION = {
    "pbitd": "    a = cq_theta(a, 0.9);\n",
    "pbitned": "    a = cq_theta(a, 0.9);\n",
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
#   E2  the CONTROLLED STATE-PREP decline control (bd drbq Inc 4/drbq.5)      1
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

# ── THE `cq_phi` SURFACE REWRITER (bd test_C_libtooling-3qlq Inc 1) ──────────
# ONE SPELLING, SHARED (Rule 14). `tools/inplace_twin_matrix.py` imports this
# function from here rather than re-implementing it, and
# `tools/angle_select_twin_matrix.py` reaches it through that import. It lives in
# THIS file because this is the dependency-free one: importing the other
# direction would give the ctest gate a `golden_multiset_audit` dependency it
# does not need.
#
# The rewrite turns the shipped REGISTER spelling into the Increment-1 VOID one,
# textually, on generated source only:
#
#     <n>        = cq_phi(<n>, <T>);   ->   cq_phi(<T>);          (lhs == arg0)
#     <TYPE> <n> = cq_phi(<x>, <T>);   ->   <TYPE> <n> = (cq_phi(<T>), <x>);
#     <n>        = cq_phi(<x>, <T>);   ->   <n> = (cq_phi(<T>), <x>);
#
# The alias half is NOT decoration: `int cqa = cq_phi(cq0,.07)` and
# `T r = cq_phi(p,.05)` are ALIAS spellings in the sibling instruments, and
# dropping the alias would silently change which register a later line names.
#
# ⚠ EVERY OUTPUT FORM IS EXACTLY ONE STATEMENT, AND THAT IS A CORRECTNESS
# REQUIREMENT, NOT A STYLE ONE. It was found by reading a generated sample rather
# than by reasoning (Rule 11). The angle-select generator writes its arms
# BRACE-LESS —
#     if (q == 5) r = cq_phi(r, A); else r = cq_phi(r, B);
# — so a two-statement expansion `r = r; cq_phi(B);` puts the SECOND statement
# OUTSIDE the `else`, and the B phase then fires unconditionally: a DIFFERENT
# PROGRAM that compiles, links and runs. The comma operator keeps the alias and
# the phase in one expression (`(void_expr, x)` is C11 6.5.17), so the rewrite is
# safe at any site a single statement is legal — which is every site these
# generators write.
#
# ⚠ AND THE `decl` GROUP EXCLUDES THE STATEMENT KEYWORDS. Without that, `else` in
# `else r = cq_phi(r, B);` matches "an identifier followed by whitespace" and is
# read as a TYPE, so the rewrite forces the comma form where the plain
# `cq_phi(B);` is right. Same sample, same reading.
#
# ⚠ MEASURED SIDE EFFECT, RECORDED SO NOBODY RE-DISCOVERS IT AS A BUG: an Rz ARM
# on a register nothing else reads becomes `-Wunused-variable` under `void`, and
# that is the surface change itself rather than a rewrite artefact. On the
# register surface `if (c) { r = cq_phi(r, .9); }` READS `r` (it is the call's
# arg-0); under `void` the arm is `cq_phi(.9);` and `r` is assigned and never
# read. Swept 2026-09-05, `clang -fsyntax-only -Wall -Wextra`, 2882 generated
# void sources across all three instruments and all their pools: 0 compile
# failures; 22 texts carry a warning other than `-Wunused-parameter`, 15 of which
# carry the identical one on the register surface, and the 7 that do not are all
# exactly this — `cons=none` / `use=none` cells whose arm is a `cq_phi`.
#
# ⚠ IT IS TEXTUAL, ON TEXT THESE GENERATORS WROTE, and it is not a C parser: a
# nested call or a comma inside the arg-0 expression would defeat it. Every
# generated `cq_phi` site in all three instruments is a bare identifier arg-0, so
# the restriction is real and currently vacuous. It ASSERTS rather than silently
# passing text through: an unrewritten `cq_phi(` with two arguments left in the
# output would compile against the void header as a wrong-arity call and read
# like a frontend bug.
PHI_SURFACES = ("register", "void")

# ── ONE TABLE PAIR PER SURFACE, and the LIVE names belong to the SHIPPED one ──
# bd 3qlq Increment 1. Before it, `register` was the only surface and owned the
# unqualified names; after it, `a = cq_phi(a, T)` does not compile against
# include/CQ.h at all and every verdict in those two files is HISTORY.
#
# The rule this encodes, and it is the rule rather than a convenience: THE FILE
# THE SHIPPED GATE READS ALWAYS HOLDS THE SHIPPED SURFACE'S VERDICTS. So the void
# tables took the live names and the register tables were renamed to `.register.`
# with their CONTENT byte-unchanged (`git log --follow` recovers them either way).
# The alternative — leaving the retired surface on the unqualified name and
# giving the live gate a `_void` one — puts the gate on the qualified name and the
# dead measurements on the name every doc, every memory and every future reader
# reaches for first. That is how F-L5-7(a) happened: an invocation kept pointing
# at the artifact of a surface that no longer existed, and it took a 349-failure
# run to notice.
SURFACE_TABLES = {
    "void":     ("loop_twin_matrix.expected.txt",
                 "loop_twin_matrix.quarantine.txt"),
    "register": ("loop_twin_matrix.expected.register.txt",
                 "loop_twin_matrix.quarantine.register.txt"),
}

# Statement keywords that can stand immediately before an assignment and would
# otherwise be read as a type by the `decl` group. `else` is the one that bit;
# the rest are here so the next generator shape does not have to rediscover it.
_STMT_KW = ("else", "do", "return", "case", "default")

_PHI_CALL = re.compile(
    # `\b` AFTER the indent, applying to BOTH alternatives, is load-bearing: a
    # negative lookahead alone does not stop the engine from starting the match
    # INSIDE a word, and it did — `else r = cq_phi(r, B);` matched from "lse",
    # whose lookahead passes, and read `lse ` as a declaration. Measured on the
    # angle-select generator's brace-less arm, which is the same sample that
    # produced the one-statement rule above.
    (r"(?P<indent>[ \t]*)\b"
     r"(?:(?P<decl>(?:(?!(?:%s)\b)[A-Za-z_][A-Za-z0-9_]*[ \t]+)+)"
     r"(?P<name1>[A-Za-z_][A-Za-z0-9_]*)"
     r"|(?P<name2>[A-Za-z_][A-Za-z0-9_]*))"
     r"[ \t]*=[ \t]*cq_phi\([ \t]*(?P<arg0>[A-Za-z_][A-Za-z0-9_]*)[ \t]*,"
     r"[ \t]*(?P<angle>[^,()]*?)[ \t]*\)[ \t]*;") % "|".join(_STMT_KW))

# The REGISTER spelling, for the post-condition assert only: `cq_phi(` then a
# first argument containing no paren, then a comma.
_PHI_CALL_TWOARG = re.compile(r"cq_phi\([^,;()]*,")


# ── WHICH SURFACE DOES A `CQ.h` DECLARE? ───────────────────────────────────
# bd 3qlq Inc 1, Rule-13 round-1 review finding F-L5-7(b). This used to be the
# literal substring test `"void cq_phi(double" not in text`, and the SHIPPED
# header spells the declaration column-aligned —
#     void                cq_phi     (double angle);
# — so `--phi-surface void` REFUSED the very header it was written to require,
# with a message asserting that header was a `register`-surface one. That is the
# instrument telling a falsehood about the artifact it was handed, which is the
# whole class of defect a guard exists to prevent.
#
# So the question is asked of DECLARATIONS, not of prose: C comments are stripped
# first (the shipped header's own commentary names both surfaces, line 52 quoting
# the retired `cq_phi_<sfx>(x, angle)` family it replaces), and each side is a
# whitespace-insensitive regex.
#
# It is a PURE FUNCTION of the header text on purpose: `loop_twin_matrix_
# quarantine_test.py` asserts it says `void` for the real `include/CQ.h` and
# `register` for the pre-3qlq one, so the guard is exercised against the SHIPPED
# header rather than against a stand-in — which is exactly what F-L5-7(b) says
# was missing.
_C_COMMENT = re.compile(r"/\*.*?\*/|//[^\n]*", re.S)
_DECL_VOID_PHI = re.compile(r"\bvoid\s+cq_phi\s*\(\s*double")
_DECL_REG_PHI = re.compile(r"\bcq_phi_[A-Za-z0-9_]+\s*\(|#\s*define\s+cq_phi\b")


def phi_surface_of_header(text):
    """`"void"` | `"register"` | `"hybrid"` | `"unknown"` for one CQ.h text."""
    code = _C_COMMENT.sub(" ", text)
    v = bool(_DECL_VOID_PHI.search(code))
    r = bool(_DECL_REG_PHI.search(code))
    if v and r:
        return "hybrid"
    if v:
        return "void"
    if r:
        return "register"
    return "unknown"


def phi_void_source(text):
    """Rewrite generated C from the `register` cq_phi surface to the `void` one.

    Returns the rewritten text. Raises AssertionError if a two-argument
    `cq_phi(` survives — see the block comment above for why that is an assert
    and not a pass-through.
    """
    def one(m):
        ind, angle, arg0 = m.group("indent"), m.group("angle"), m.group("arg0")
        decl, name = m.group("decl"), m.group("name1") or m.group("name2")
        if not decl and name == arg0:
            return "%scq_phi(%s);" % (ind, angle)
        # ONE statement, always — see the block comment: a brace-less arm makes a
        # two-statement expansion a silently different program.
        return "%s%s%s = (cq_phi(%s), %s);" % (ind, decl or "", name, angle, arg0)

    out = _PHI_CALL.sub(one, text)
    # The assertion looks for the REGISTER form specifically — `cq_phi(<expr>,`
    # with no paren in the first argument — rather than "a comma anywhere inside
    # the parens", which would fire on the rewriter's own comma form
    # `(cq_phi(T), x)`. (It did; caught by the same sample that found the
    # brace-less `else`.)
    left = _PHI_CALL_TWOARG.search(out)
    assert left is None, (
        "phi_void_source left a two-argument cq_phi behind: %r"
        % out[left.start():left.start() + 60] if left else "")
    return out

# TWO TRIPS, and two is not arbitrary: it is the smallest count at which the back
# edge is taken, so the "next activation" the window lemma reasons about actually
# exists in the trace, and it is small enough that a divergence is readable.
TRIPS = 2


def sources(prefix, region, suffix, record="none", rgate="none",
            surface="register"):
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
    return _wrap(body, second, R, surface,
                 index=region in INDEXED_REGION,
                 postloop=POSTLOOP_FOR_REGION.get(region, ""))


def _wrap(body, second, R, surface="register", index=False, postloop=""):
    """The rolled/unrolled pair around ONE body. Shared by `sources` and by the
    quarantine's boundary controls so that a control can never drift into being
    a differently-shaped program than the cells it bounds.

    `index` binds the loop counter `i` on the UNROLLED side (bd 3qlq Inc 1, the
    CLEARANCE finding C-1's matrix axis). The rolled side already has it from the
    `for`; the flat side is the SAME body text repeated, so a body that reads `i`
    — D4's per-bit idiom `(a >> i) & 1`, which is the whole point of sub-grid F —
    would not compile there. It gets `int i = 0;` before the repetitions and
    `i = i + 1;` after each one, which is what the `for` does and nothing else;
    `-O1` constant-propagates it, so the flat program is the hand-written
    `(a>>0)&1 … (a>>1)&1` spelling exactly. `postloop` is a line emitted AFTER the
    loop (and after the flat repetitions), for sub-grid F's post-loop diffusion.
    BOTH default to the pre-C-1 behaviour and every one of the 274 older cells
    takes it — PROVEN by hashing all 1104 generated sources before and after this
    edit, not asserted.

    `surface` is the bd 3qlq `cq_phi` frontend surface. It is applied to the
    FINISHED text of both spellings, at the very end and in ONE place, so the
    rolled and unrolled sides can never be rewritten differently — which would
    turn a surface artefact into a `TRACE-DIVERGENCE` and blame the loop
    lowering for it. `register` returns the text untouched, byte for byte."""
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
        + "    }\n" + postloop + tail
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
        + ("    int i = 0;\n" if index else "")
        + (flat + "    i = i + 1;\n" if index else flat) * TRIPS
        + postloop
        + tail
        + "int main(void){(void)slice();return 0;}\n"
    )
    if surface == "void":
        return phi_void_source(rolled), phi_void_source(unrolled)
    return rolled, unrolled


# ── THE QUARANTINE'S BOUNDARY CONTROLS (lens L7, drbq Inc 3 round 1) ─────────
# The quarantine file's root-cause story for both classes is one sentence: the
# divergence needs BOTH the region present AND the arm rotating a register the
# condition does not read. That sentence is a claim about the compiler, so it is
# a GATE here rather than a paragraph — L7 measured both controls by hand and
# they are the two edges of the class. Neither is expressible as a matrix cell:
# `REGION` has no `none` entry, and no `RY_REGION` spelling puts the arm back on
# the condition register at an OPAQUE threshold (`der` is the literal-3.5 one, so
# it hoists differently). They are run on every invocation, alongside the cells
# — `run_boundary_controls` is called ABOVE every mode's early return, so
# `--regenerate` and `--refresh-quarantine` consult them too and REFUSE TO WRITE
# while one has moved (round-2 review F-R2-2; as first written they did not) —
# and a divergence in either is a hard failure: if a control starts diverging,
# the quarantine's two classes are no longer what the file says they are, and the
# pinned signatures below it stop meaning anything.
QUARANTINE_CONTROLS = {
    # No region at all. Isolates "the region is necessary": the class-B `add`
    # suffix on its own does NOT split the two spellings.
    "q_noregion": "        a = a + off;\n",
    # The same OPAQUE derived condition the class-A cells use, with the arm back
    # ON the condition register. Isolates "the disjoint-register arm is
    # necessary": with `a` loop-VARIANT, LICM cannot hoist the `sitofp; fadd;
    # sqrt` chain and the two spellings agree.
    "q_armoncond": "        if (sqrt(a + 3.) <= (double)off)"
                   " { a = cq_phi(a, M_PI); }\n",
}

# ── WHAT THE CONTROLS MEAN ON EACH SURFACE, PINNED. ────────────────────────
# bd 3qlq Increment 1, and this is the one place the surface change genuinely
# COSTS the instrument something, so it is written down rather than papered over.
#
# `q_armoncond` isolates "the disjoint-register arm is necessary" by putting the
# arm back ON the condition register, which keeps `a` loop-VARIANT so LICM cannot
# hoist the `sitofp; fadd; sqrt` chain. On the REGISTER surface the arm is
# `a = cq_phi(a, M_PI)` and it writes `a`; the pair comes out ACCEPT-IDENTICAL
# and the isolation is a measurement.
#
# UNDER THE VOID SURFACE THAT ISOLATION IS NOT EXPRESSIBLE. A branch phase reads
# and writes no register by construction (PRD §3), so the arm becomes
# `cq_phi(M_PI);`, `a` goes loop-INVARIANT, and the pair DECLINES on both sides
# with different messages. Nor is there a substitute: the only void gate that
# still writes a register is `cq_theta`, and an in-place Ry arm on the
# CONDITION's own wire is itself a documented loud decline (drbq Inc 1). So on
# the void surface this control cannot say "both spellings agree"; the strongest
# true statement left is "it does not DIVERGE", plus the exact verdict pinned
# here so that a change of any kind is a red.
#
# Consequence, stated so nobody quotes the void quarantine as more measured than
# it is: on the void surface the quarantine's class story is bounded by the
# `q_noregion` half (which contains no `cq_phi` at all, so its two generated
# sources are BYTE-IDENTICAL on both surfaces) and by the per-cell pinned
# signatures — not by `q_armoncond`.
SURFACE_CONTROL_VERDICTS = {
    # `register`: BOTH must be ACCEPT-IDENTICAL — the pre-3qlq behaviour,
    # unchanged, and `None` selects that stronger rule rather than a pin.
    "register": None,
    # `void`: MEASURED on the subject build of bd 3qlq Increment 1
    # (c4bd888 + the round-1 fixes), 2026-09-05. A value may be a bare verdict
    # or a (verdict, signature-digest) PAIR; the pair form is required whenever
    # the pinned verdict is a divergence, so that a control which diverges is
    # pinned exactly as strongly as a quarantined cell and a DIFFERENT
    # divergence cannot pass under the same verdict string.
    "void": {
        "q_noregion": "ACCEPT-IDENTICAL",
        # ⚠ IT DIVERGES, AND IT IS A CLASS-A INSTANCE RATHER THAN A CONTROL.
        # MEASURED, subject build, 2026-09-05: the rolled side discharges the
        # `sitofp` and `fadd` interior rails immediately after the `sqrt` and
        # LEAVES THE TOP RAIL `h3 = sqrt((double)a + 3.0)` ALLOCATED; the flat
        # side discharges all three LIFO at the end. That is bd
        # test_C_libtooling-1m5p class A verbatim — the same LIFO-inverted
        # interior placement, in the simplest shape the wrapper can build.
        #
        # Why it happens HERE and not on the register surface is the whole
        # point: class A needs `a` loop-INVARIANT so LICM can hoist the chain,
        # and on the register surface this control's arm (`a = cq_phi(a, M_PI)`)
        # WROTE `a`, which is exactly how it isolated its half. A branch phase
        # writes nothing, so under `void` the control's own body satisfies class
        # A's precondition and the control becomes an instance of the thing it
        # was bounding.
        #
        # It is kept, pinned by SIGNATURE, because in that role it is still
        # worth its milliseconds: it is the smallest class-A reproducer in the
        # tree and it fails on any change to the class. But it does NOT bound
        # the quarantine any more, and no run may be quoted as if it did.
        "q_armoncond": ("TRACE-DIVERGENCE", "dbf4c162d1de5139"),
    },
}


def control_sources(name, surface="register"):
    """(rolled, unrolled) C for one boundary control. No second register, no
    record — deliberately the plainest shape the wrapper can make."""
    return _wrap(QUARANTINE_CONTROLS[name], False, RECORD["none"], surface)


def run_boundary_controls(cfg):
    """Build and compare both QUARANTINE_CONTROLS; return
    `(failure_reports, [(name, verdict), ...])`.

    An empty failure list means both came out `ACCEPT-IDENTICAL`, i.e. the class
    story still holds. The second element is ALWAYS the measured verdict pair, so
    a caller can print it whether or not it is a gate — which is what
    `--phi-surface void` needs (see the note at the classification site).

    CALLED ON EVERY INVOCATION, including `--regenerate` and
    `--refresh-quarantine`. That is the whole point and it is a round-2 review
    fix (F-R2-2): the controls used to sit AFTER both of those early returns, so
    the one operation that RE-PINS a defect (`--refresh-quarantine`) was the one
    operation that never consulted the measurements its class story rests on,
    and `--regenerate` reported success with a control diverging.
    """
    fails, got = [], []
    for cname in sorted(QUARANTINE_CONTROLS):
        r_src, u_src = control_sources(cname, cfg.phi_surface)
        work = tempfile.mkdtemp(prefix="cqtwinctl_")
        try:
            cr = build_side(cfg, work, cname, r_src)
            cu = build_side(cfg, work, cname + "_u", u_src)
        finally:
            shutil.rmtree(work, ignore_errors=True)
        v, report = verdict(cname, cr, cu)
        got.append((cname, v.split("\t")[0]))
        pins = SURFACE_CONTROL_VERDICTS[cfg.phi_surface]
        if pins is not None:
            want_v = pins[cname]
            want_sig = None
            if isinstance(want_v, tuple):
                want_v, want_sig = want_v
            if want_sig is not None and v.split("\t")[0] == want_v:
                # A pinned DIVERGENCE is pinned by its signature too — the same
                # rule the quarantine applies to a cell, for the same reason.
                d = divergence_signature(cr.trace, cu.trace)[0]
                if d != want_sig:
                    fails.append(
                        "%s: BOUNDARY CONTROL still diverges but DIFFERENTLY "
                        "(pinned %s, got %s).\n    A control pinned to a "
                        "divergence is pinned to THAT divergence; this one "
                        "moved."
                        % (cname, want_sig, d))
                continue
            # A PINNED verdict, not a weaker gate: the control still fails on any
            # change at all, including a change to ACCEPT-IDENTICAL. See
            # `SURFACE_CONTROL_VERDICTS` for why the void surface cannot use the
            # stronger identity rule and what that costs the quarantine's class
            # story. `--regenerate` does NOT rewrite these — moving a control is
            # a human decision with a measurement attached, exactly like moving a
            # quarantined signature.
            want = want_v
            if v.split("\t")[0] != want:
                fails.append(
                    "%s: BOUNDARY CONTROL moved (pinned %s, got %s).\n"
                    "    On the `%s` surface this control's verdict is PINNED in "
                    "SURFACE_CONTROL_VERDICTS,\n    because it is what bounds "
                    "the quarantine's class story. It just changed, so that\n"
                    "    story is no longer the measured one — a human decides "
                    "whether the pin moves.%s"
                    % (cname, want, v.split("\t")[0], cfg.phi_surface,
                       "\n" + report if report else ""))
            continue
        # `ACCEPT-IDENTICAL-WARN` counts as identical: both sides warned with the
        # SAME message, which is not a divergence. A one-sided warning is already
        # `WARN-ASYMMETRY` and fails here like any other non-identity.
        if not v.startswith("ACCEPT-IDENTICAL"):
            fails.append(
                "%s: BOUNDARY CONTROL is no longer ACCEPT-IDENTICAL (got %s).\n"
                "    The quarantine's root cause says the divergence needs BOTH "
                "the region\n    AND an arm off the condition register. This "
                "control isolates one of\n    those two halves, and it just "
                "moved — the quarantine's class story is\n    no longer the "
                "measured one.%s"
                % (cname, v.split("\t")[0], "\n" + report if report else ""))
    return fails, got


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
        # bd 3qlq Inc 1, `--phi-surface void` ONLY: the count of `void @cq_phi`
        # calls left in the LOWERED IR. A binary that predates Increment 1 has no
        # concept of that surface — it neither lowers nor deletes the call — so
        # the module cannot link (no such runtime symbol, and this epic adds none,
        # PRD D3). That is the PRE-increment DISPOSITION, not a harness break, so
        # stages 2b/3/4 are skipped and the side is reported as itself.
        #
        # `phi_asked` is NOT redundant with `phi_unlowered == 0`. A side that
        # DECLINED never reaches the check, so a bare `0` would read as "this
        # side lowered the void surface cleanly" when in fact it was never asked.
        # That distinction is the whole content of a mixed cell.
        self.phi_unlowered = 0
        self.phi_asked = False


def _resid(side):
    """How to read one side's residual-`cq_phi` state, in words.

    A side that DECLINED was never asked — reporting its count as `0` would say
    "this side lowered the void surface cleanly", which is the opposite of what
    happened. `phi_asked` is what tells the two apart.
    """
    if not side.phi_asked:
        return "not asked (%s)" % ("declined" if side.exit else "harness error")
    return "%d residual" % side.phi_unlowered


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
    if cfg.phi_surface == "void":
        # Read the LOWERED IR, not the trace: an unlowered `cq_phi` never
        # reaches a trace, because the module does not link.
        with open(s2) as f:
            s.phi_unlowered = f.read().count("call void @cq_phi(")
        s.phi_asked = True
        if s.phi_unlowered:
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


# ── THE QUARANTINE ──────────────────────────────────────────────────────────
# A QUARANTINE IS NOT A BLESSING. `loop_twin_matrix.expected.txt` says, and keeps
# saying, that `TRACE-DIVERGENCE` may never be recorded as an expected verdict —
# a table entry that says "this pair may differ" retires the one gate in the tree
# that can see the F-4 class. The quarantine does NOT relax that. It records a
# FILED DEFECT together with the EXACT way it currently manifests, and it fails
# in BOTH directions:
#
#   * the cell stops diverging          -> FAIL ("quarantine stale — remove it")
#   * the cell diverges DIFFERENTLY     -> FAIL (the signature moved: either the
#                                         defect changed or something new landed
#                                         on top of it, and both need a human)
#   * the cell is in BOTH files         -> FAIL (a verdict and a quarantine are
#                                         two different claims about one cell)
#   * a NON-quarantined cell diverges   -> FAIL, exactly as before
#
# So the only thing that passes is "these cells, diverging in exactly these ways".
# The signature is a digest of the full unified diff of the two traces — not a
# line count, not a first-difference, not a verdict — so a divergence that grows,
# shrinks, moves or changes opcode is a red. The first differing line PAIR is
# stored beside it unhashed, because a digest alone is unreadable and the next
# person needs to see what the defect looks like without running anything.
#
# Every entry names its CLASS, its bd issue, and the OWNING SUBSYSTEM **with a
# direction** — which side is the deficient one. The direction is the part people
# get wrong: for class B the ROLLED side is the better circuit and "fix the roll
# to match the flat" would make the emitted circuit worse (lens L7).
QUARANTINE_KEYS = ("class", "bd", "owner", "digest", "rolled", "unrolled")


def divergence_signature(rolled_trace, unrolled_trace):
    """(digest, first_rolled_line, first_unrolled_line) for a diverging pair.

    The digest covers the WHOLE unified diff including its `@@` hunk headers, so
    a divergence that merely moves position is a different signature. `<end>` is
    the sentinel for "this side had no such line", which is how a pure
    truncation reads.
    """
    d = list(difflib.unified_diff(rolled_trace.splitlines(),
                                  unrolled_trace.splitlines(),
                                  fromfile="rolled", tofile="unrolled",
                                  lineterm="", n=3))
    digest = hashlib.sha256("\n".join(d).encode()).hexdigest()[:16]
    rl, ul = rolled_trace.splitlines(), unrolled_trace.splitlines()
    i = next((k for k in range(max(len(rl), len(ul)))
              if k >= len(rl) or k >= len(ul) or rl[k] != ul[k]), 0)
    return (digest,
            rl[i] if i < len(rl) else "<end>",
            ul[i] if i < len(ul) else "<end>")


def load_quarantine(path):
    """name -> {class, bd, owner, digest, rolled, unrolled}.

    Block format, blank-line separated, `#` comments. Deliberately NOT a one-line
    record: the whole point is that a reader can see the defect without running
    the gate, and a 16-hex digest crammed onto the end of a row is not that.
    """
    if not path or not os.path.exists(path):
        return {}
    out, cur, name = {}, {}, None
    with open(path) as f:
        for lineno, raw in enumerate(f, 1):
            # A comment is a WHOLE line starting with `#`, never a trailing `#`:
            # a pinned trace line is stored verbatim and must not be truncated by
            # one. A comment also does not END a block — only a blank line does.
            if raw.lstrip().startswith("#"):
                continue
            line = raw.rstrip("\n")
            if not line.strip():
                if name:
                    out[name] = cur
                cur, name = {}, None
                continue
            key, _, val = line.strip().partition(" ")
            val = val.strip()
            if key == "cell":
                if name:
                    out[name] = cur
                cur, name = {}, val
            elif key in QUARANTINE_KEYS:
                if name is None:
                    raise SystemExit("%s:%d: `%s` before any `cell`"
                                     % (path, lineno, key))
                cur[key] = val
            else:
                raise SystemExit("%s:%d: unknown key %r" % (path, lineno, key))
    if name:
        out[name] = cur
    for n, rec in out.items():
        missing = [k for k in QUARANTINE_KEYS if k not in rec]
        if missing:
            raise SystemExit("%s: cell %s is missing %s — a quarantine entry "
                             "without a class, an owner and a signature is a "
                             "blessing, which this file may not contain"
                             % (path, n, ", ".join(missing)))
    return out


def write_quarantine(path, quar, order):
    with open(path, "w") as f:
        f.write(QUARANTINE_HEADER)
        f.write("\n")
        for n in order:
            rec = quar[n]
            f.write("cell     %s\n" % n)
            for k in ("class", "bd", "owner", "digest", "rolled", "unrolled"):
                f.write("%-8s %s\n" % (k, rec[k]))
            f.write("\n")


def cell_name(cell):
    """THREE grammars, and the arity is what tells them apart — deliberately, so
    that adding an axis can never rename a committed cell:

      `m_<prefix>_<region>_<suffix>`                    the 120 record-free cells
      `m_<prefix>_<region>_<suffix>_<record>`           the 36 RECORD cells
      `m_<prefix>_<region>_<suffix>_<record>_<rgate>`   the 118 Ry-ARM cells

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
    # E2 — the CONTROLLED STATE-PREP decline control (bd drbq Inc 4 / drbq.5).
    # Spelled with the `ry` PREFIX rather than at the `none` the other two
    # decline controls use, and that is not a style choice — it was MEASURED,
    # both ways, on the pre-Inc-4 oracle `b506b3b`. With no a-register gate in
    # the body `a` is LOOP-INVARIANT, LICM hoists the literal compare out of the
    # loop, and `("none", "rprep", ...)` declines `condition predates a
    # non-diagonal gate` on the ROLLED side (the hoist) against `control flow` on
    # the flat one: a cell whose rolled disposition is decided before the loop
    # clause is ever reached, which is the docstring's OPAQUE-THRESHOLD
    # phenomenon one axis over. The `ry` prefix keeps the condition register
    # loop-VARIANT — the shape a customer writes, and the shape in which the loop
    # clause is the live question.
    out += [("ry", "rprep", "none", "none", "none")]
    return out


# ── SUB-GRID F — THE MIXED LOOP (bd 3qlq Inc 1, the CLEARANCE finding C-1) ──
#
# WHAT 274 CELLS COULD NOT SEE, and why it is a SECOND-CARRIED-REGISTER axis
# rather than another region spelling. C-1 needs THREE things at once: a
# condition register that is loop-INVARIANT, a condition DERIVED per trip from
# it (so a template rail is minted and must be discharged every iteration), and
# a SECOND register that is loop-CARRIED (so `collapseRailPhisIn` returns
# `Collapsed` and the invariant-root path was never asked). Sub-grid B moves a
# second register but its regions are compares on `a`, which are hoist-inert or
# opaque; no cell anywhere read the loop index. So the shape sat outside the
# instrument, and the clearance found it by hand.
#
#   F1  polarity x post-loop-diffusion x how `r` is carried                  8
#   F2  the RECORD axis on each register, at the diffusing region            2
# 10 cells. Kept small deliberately: this gate is already the suite's long pole
# at ~400 s, and the population beyond these 14 is measured in
# `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 rather than paid for on every run.
F_REGION = ("pbit", "pbitd", "pbitne", "pbitned")
# How the second register is CARRIED. TWO `RGATE` spellings are deliberately
# ABSENT, and both exclusions are MEASURED rather than assumed:
#
#   * `rzpost` — under the shipped `void` surface it rewrites to an UNCONTROLLED
#     `cq_phi`, which owner decision D2 DELETES as a global phase, so `r` would
#     not be carried at all and the cell would not be a mixed loop.
#
#   * `addpost` — the twin is NOT FAITHFUL for it, which is a property of
#     `clang -O1` and not of the lowering. MEASURED on the C-1 fix build with
#     `--regenerate`, which REFUSED TO WRITE and reported all four `addpost`
#     cells as `TRACE-DIVERGENCE`; the traces are MULTISET-IDENTICAL
#     (`diff <(sort rolled) <(sort unrolled)` empty, same `_unc`/free/mint counts,
#     same line count) and differ only in the POSITION of one
#     `cqrt_addc_i32(h1, 3)`. Reading the two stage-1 modules (Rule 11, not
#     reasoning): the flat spelling keeps the volatile `load @off` where the
#     source put it and SINKS the `add nsw %7, %2` PAST THE SECOND REGION, which
#     a loop body cannot do across the back edge. So the two SOURCES are not the
#     same program after `-O1` — the clearance's own `d6u` limit, and the same
#     one measured this round on `d1c` (whose three `r^=9` fold to one) and `n1`.
#     Quarantining it would pin a `-O1` scheduling artefact as if it were a
#     filed compiler defect, which is what the quarantine file's own header
#     forbids. The in-place-`add` carry shape IS covered — by the population
#     table in `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 (`d1c`, `d10`, `n1`), where
#     the multiset equality can be stated instead of hidden behind a digest.
F_RGATE = ("rypost", "rypre")


def f_cells():
    """The mixed-loop sub-grid (bd 3qlq Inc 1, CLEARANCE C-1). See `F_*` above."""
    out = [("none", g, "none", "none", rg)
           for g in F_REGION for rg in F_RGATE]
    # F2 — a record of the INVARIANT register and one of the CARRIED register,
    # at the region that also diffuses. `premark`/`rpremark` are read AFTER the
    # loop, which is where a stale record shows.
    out += [("none", "pbitd", "none", k, "rypost")
            for k in ("premark", "rpremark")]
    return out


def cells_of_matrix():
    """The full cell list: the 120-cell PREFIX x REGION x SUFFIX product with no
    record, plus the 36-cell record sub-grid (see `RECORD_GRID_*`), plus the
    118-cell controlled-Ry-arm sub-grids (see `RY_*`, whose sub-grid E2 is the
    bd drbq Inc-4 controlled-state-prep decline control), plus the 10-cell
    MIXED-LOOP sub-grid F (see `F_*` — bd 3qlq Inc 1, the Rule-13 CLEARANCE
    finding C-1, the axis 274 cells did not have). 284 cells.

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
    f = f_cells()
    assert (len(base), len(rec), len(ry), len(f)) == (120, 36, 118, 10), \
        "sub-grid sizes moved: %d/%d/%d/%d" % (len(base), len(rec), len(ry),
                                               len(f))
    cells = base + rec + ry + f
    names = [cell_name(c) for c in cells]
    assert len(set(names)) == len(names), "duplicate cell name"
    return cells


def run_cell(cfg, cell):
    prefix, region, suffix, record, rgate = cell
    name = cell_name(cell)
    rolled_src, unrolled_src = sources(prefix, region, suffix, record, rgate,
                                       cfg.phi_surface)
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
    # bd 3qlq Inc 1 — `--phi-surface void` ONLY, and asked FIRST because a side
    # in this state has no trace to compare and no diagnostic to report: the
    # module lowered cleanly and simply still names a symbol nothing defines.
    # Both halves are named, because "which side failed to lower it" is the
    # information — under `void` a rolled/unrolled asymmetry here would mean the
    # deletion or the kickback reached one spelling and not the other.
    if rolled.phi_unlowered or unrolled.phi_unlowered:
        which = ("BOTH" if rolled.phi_unlowered and unrolled.phi_unlowered
                 else "ROLLED" if rolled.phi_unlowered else "UNROLLED")
        return ("PHI-UNLOWERED-%s\trolled %s, unrolled %s"
                % (which, _resid(rolled), _resid(unrolled))), None
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
    # `--include-dir` is an ALIAS, not a second option: the committed ctest
    # invocation spells it `--include` and must stay byte-identical, while the
    # bd 3qlq briefs spell it `--include-dir`. One dest, two spellings.
    ap.add_argument("--include", "--include-dir", required=True, dest="include")
    ap.add_argument("--runtime", required=True)
    ap.add_argument("--templates", required=True)
    ap.add_argument("--expected", default="",
                    help="the committed disposition table. Empty (the default) "
                         "resolves to the table of the SURFACE being run — see "
                         "`SURFACE_TABLES`: the `void` surface owns the LIVE "
                         "names, the retired `register` surface owns the "
                         "`.register.txt` ones.")
    ap.add_argument("--ld", default=os.environ.get("CQ_LD", ""),
                    help="the bd dgn5 link wrapper (CMake exports it as CQ_LD); "
                         "empty falls back to the clang driver")
    ap.add_argument("--quarantine", default="",
                    help="the PINNED-SIGNATURE quarantine of filed divergences. "
                         "A quarantine is NOT a blessing — read that file's "
                         "header before touching it. Empty (the default) "
                         "resolves per surface exactly as --expected does.")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--phi-surface", choices=PHI_SURFACES, default="register",
                    help="the `cq_phi` FRONTEND surface the cells are generated "
                         "against (bd test_C_libtooling-3qlq Increment 1). "
                         "`void` is the SHIPPED surface and the one the "
                         "`e2e-loop-twin-matrix` ctest entry runs: the "
                         "register-free branch phase `cq_phi(T)`. `register` is "
                         "the RETIRED 15-width `a = cq_phi(a, T)`; it remains "
                         "the argparse default so that a by-hand invocation "
                         "written before Increment 1 keeps its meaning, but it "
                         "is UNREACHABLE against the shipped include/CQ.h and "
                         "the header guard says so in one line rather than "
                         "producing 175 harness errors. Each surface reads and "
                         "writes ITS OWN expected table and quarantine "
                         "(`SURFACE_TABLES`), so no file on disk is ever read as "
                         "a measurement of a surface it was not measured on.")
    ap.add_argument("--out", default="",
                    help="also write the verdict table to FILE (name + verdict, "
                         "one row per cell, the same two columns --regenerate "
                         "writes), WITHOUT touching the committed table. This is "
                         "how the pre/post records under "
                         "docs/prd/phase-04-swap-route-control/inc1-records/ are "
                         "taken.")
    ap.add_argument("--regenerate", action="store_true",
                    help="rewrite the expected table from this run. DELIBERATE "
                         "ONLY — say which cells moved and why (Rule 12).")
    ap.add_argument("--refresh-quarantine", action="store_true",
                    help="rewrite the DIGEST and first-differing-line pair of "
                         "the cells ALREADY listed in the quarantine, from this "
                         "run. It can neither add nor remove a cell — adding one "
                         "is a human decision with a bd issue attached. Exactly "
                         "as deliberate as --regenerate: it re-pins a defect "
                         "whose manifestation CHANGED, so say in the commit "
                         "message what moved and why (Rule 12).")
    cfg = ap.parse_args()

    # ── THE TABLES THIS RUN OWNS. Resolved from the surface, never from a
    #    default baked into argparse, so that adding a surface cannot leave a
    #    gate silently reading the previous one's file (`SURFACE_TABLES`).
    _exp, _quar = SURFACE_TABLES[cfg.phi_surface]
    if not cfg.expected:
        cfg.expected = os.path.join(HERE, _exp)
    if not cfg.quarantine:
        cfg.quarantine = os.path.join(HERE, _quar)

    # ── THE HEADER GUARD, both directions (bd 3qlq Inc 1; round-1 finding
    #    F-L5-7). The surface a run GENERATES and the surface its --include-dir
    #    DECLARES must agree, or every cell fails at stage 1 and the wall of
    #    stage-1 failures reads like a wall of lowering declines. It was
    #    one-directional and whitespace-sensitive, and BOTH halves of that cost a
    #    measured run: `void` refused the shipped header (F-L5-7(b), the literal
    #    substring vs the header's column alignment) and `register` was never
    #    asked at all, so the committed ctest invocation produced 175
    #    HARNESS-ERRORs plus 172 "verdict changed" against the shipped header
    #    instead of one line saying which surface it was handed (F-L5-7(a)).
    hdr = os.path.join(cfg.include, "CQ.h")
    try:
        hdr_surface = phi_surface_of_header(open(hdr).read())
    except OSError as e:
        print("--phi-surface %s: cannot read %s (%s)" % (cfg.phi_surface, hdr, e))
        return 2
    if hdr_surface != cfg.phi_surface:
        print("--phi-surface %s: %s declares the `%s` cq_phi surface.\n"
              "  Every generated cell would fail at STAGE 1 (clang), and a wall "
              "of stage-1\n  failures reads like a wall of lowering declines — "
              "which is what this guard\n  exists to stop it doing. The shipped "
              "include/CQ.h declares `void cq_phi(double)`\n  (PRD §4.1) and is "
              "the `void` surface; the retired 15-width `cq_phi_<sfx>(x, angle)`\n"
              "  family is the `register` one and no longer exists in the tree.\n"
              "  Either pass --phi-surface %s or point --include-dir at a %s "
              "header."
              % (cfg.phi_surface, hdr, hdr_surface, hdr_surface,
                 cfg.phi_surface))
        return 2

    cells = cells_of_matrix()
    results = {}
    # A PROCESS pool, not a thread pool — stage 2b runs in-process (see
    # `_pair_check`) and mutates the interpreter's recursion limit.
    with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
        for name, rolled, unrolled in ex.map(_run_cell_star,
                                             [(cfg, c) for c in cells]):
            results[name] = (rolled, unrolled)

    # UNDER `void` THE QUARANTINE IS READ FOR ITS CELL NAMES AND NOT FOR ITS
    # SIGNATURES, and the split is exactly the split between what the file claims
    # and what it measures. Its CLAIM — "this cell holds a FILED, root-caused
    # defect (bd test_C_libtooling-1m5p class A, bd test_C_libtooling-a3z7 class
    # B)" — is about `Uncomputation`/`FreePoint` interior placement and
    # `ArithLowering` M-C, neither of which has anything to do with `cq_phi`; it
    # is surface-independent. Its SIGNATURE is a SHA-256 digest of a
    # REGISTER-surface trace and cannot mean anything about a void one.
    #
    # So under `void` a quarantined cell that diverges is recorded as a VERDICT
    # carrying its bd issue, not as a hard failure; a quarantined cell that does
    # NOT diverge is NOT "quarantine stale" (that verdict belongs to the surface
    # the entry was measured on); and a NON-quarantined divergence is a hard
    # failure exactly as it always was — which is the half that matters.
    #
    # MEASURED on the pre-3qlq oracle 52d7764, 274 cells: the 13 void divergences
    # are a SUBSET of the 15 register-surface quarantined cells, with ZERO new
    # ones. The 2 that drop out are `..._rzpost`, whose `r = cq_phi(r, .125)`
    # RGATE becomes an uncontrolled void filler the oracle leaves unlowered.
    quar = load_quarantine(cfg.quarantine)

    got, hard, sig = {}, {}, {}
    for name in sorted(results):
        v, report = verdict(name, *results[name])
        got[name] = v
        if v == "TRACE-DIVERGENCE":
            sig[name] = divergence_signature(results[name][0].trace,
                                             results[name][1].trace)
        if report:
            hard[name] = report

    # ── the quarantine, applied. Both directions, and neither is optional. ──
    qfails, quarantined_ok = [], set()
    for name in sorted(quar):
        rec = quar[name]
        if name not in got:
            qfails.append(
                "%s: QUARANTINED but not a cell in this run — the axis was "
                "renamed or the cell deleted. A quarantine may not outlive its "
                "cell: re-point it or remove it (bd %s)." % (name, rec["bd"]))
            continue
        if got[name] != "TRACE-DIVERGENCE":
            qfails.append(
                "%s: QUARANTINE STALE — REMOVE IT.\n"
                "    the cell no longer diverges; its verdict is now %s.\n"
                "    A quarantine pins a LIVE defect (bd %s, class %s). If that\n"
                "    defect is fixed, delete this entry and let --regenerate\n"
                "    record the cell's real verdict in the expected table."
                % (name, got[name].split("\t")[0], rec["bd"], rec["class"]))
            continue
        digest, rline, uline = sig[name]
        if digest != rec["digest"]:
            qfails.append(
                "%s: QUARANTINED SIGNATURE CHANGED — this is a red, not a "
                "refresh.\n"
                "    pinned : %s\n    got    : %s\n"
                "    first differing line now:\n      rolled   : %s\n"
                "      unrolled : %s\n"
                "    The filed defect (bd %s, class %s, %s) manifests "
                "DIFFERENTLY than\n"
                "    when it was pinned. Either it moved or something new landed "
                "on top\n    of it; both need a human. --refresh-quarantine "
                "re-pins it, and is as\n    deliberate as --regenerate."
                % (name, rec["digest"], digest, rline, uline,
                   rec["bd"], rec["class"], rec["owner"]))
            continue
        quarantined_ok.add(name)

    # ── the quarantine's two BOUNDARY CONTROLS. See `QUARANTINE_CONTROLS`. ──
    # Run HERE, above every mode's early return, so that they are consulted on
    # EVERY invocation — plain, `--regenerate` and `--refresh-quarantine` alike
    # (round-2 review F-R2-2; they used to be unreachable in the latter two,
    # which is exactly backwards).
    ctlfails, ctlgot = run_boundary_controls(cfg)

    def write_out(rows):
        """`--out`: the same two columns --regenerate writes, no header. The
        record file that quotes it supplies the provenance (the Inc-4 precedent,
        docs/prd/phase-04-swap-route-control/inc4-records/)."""
        if not cfg.out:
            return
        with open(cfg.out, "w") as f:
            for n in sorted(rows):
                f.write("%-24s %s\n" % (n, rows[n]))

    # THE `void` SURFACE NO LONGER HAS A MODE OF ITS OWN, and that is the
    # substantive half of this change (bd 3qlq Inc 1, round-1 finding F-L5-7).
    # It used to measure, print a tally and return — reading no expected table,
    # reading the quarantine for CELL NAMES only, and refusing to write either,
    # because both files held `register`-surface measurements and neither claim
    # survived the surface change. That was right while the register tables were
    # the only ones on disk. It is wrong now that `void` is the SHIPPED surface
    # and the ctest entry runs it: a gate whose expected table is "none" pins
    # nothing, so a cell may change disposition run to run with no red anywhere
    # — which is precisely what tools/loop_twin_matrix.expected.txt exists to
    # stop (Rule 12, and the 8h7d.5 F-4 argument in the docstring).
    #
    # So `void` falls through into the SAME gate below, against ITS OWN table
    # pair (`SURFACE_TABLES`), with the same quarantine semantics in both
    # directions, the same two write modes, and the same boundary controls. One
    # code path, two surfaces, no mode-specific verdict handling to drift.

    if cfg.refresh_quarantine:
        if not quar:
            print("no quarantine file at %s — nothing to refresh" % cfg.quarantine)
            return 1
        if ctlfails:
            # Re-pinning a signature measured against a moved control would pin
            # the wrong defect: the class story the quarantine documents is no
            # longer the measured one, so the signature has nothing to mean.
            print("REFUSED: a BOUNDARY CONTROL has moved, so nothing is re-pinned "
                  "and %s is UNCHANGED." % cfg.quarantine)
            for r in ctlfails:
                print(r)
            return 1
        missing = [n for n in quar if n not in got
                   or got[n] != "TRACE-DIVERGENCE"]
        if missing:
            print("REFUSED: these quarantined cells do not diverge in this run, "
                  "so there is no signature to pin:\n  " + "\n  ".join(missing))
            print("Remove them from the quarantine instead — a quarantine that "
                  "cannot be measured is a blessing.")
            return 1
        for n in quar:
            quar[n]["digest"], quar[n]["rolled"], quar[n]["unrolled"] = sig[n]
        write_quarantine(cfg.quarantine, quar, sorted(quar))
        print("re-pinned %d quarantined signature(s) in %s"
              % (len(quar), cfg.quarantine))
        return 0

    if cfg.regenerate:
        # THE REFUSAL COMES FIRST, AND IT IS A REFUSAL TO WRITE. Round-2 review
        # F-R2-1: this used to write the table and only THEN print "REGENERATION
        # REFUSED", which put the exact verdict `EXPECTED_HEADER` forbids
        # (`TRACE-DIVERGENCE`) on disk under a message claiming nothing had been
        # written. A hard failure now leaves `cfg.expected` byte-unchanged.
        blocking = [r for n, r in sorted(hard.items())
                    if n not in quarantined_ok] + qfails + ctlfails
        if blocking:
            print("REGENERATION REFUSED TO HIDE %d HARD FAILURE(S) — %s is "
                  "UNCHANGED:" % (len(blocking), cfg.expected))
            for r in blocking:
                print(r)
            return 1
        # QUARANTINED CELLS ARE NOT WRITTEN TO THE EXPECTED TABLE. The two files
        # make two different claims and a cell may be in exactly one of them —
        # otherwise the next `--regenerate` writes `TRACE-DIVERGENCE` into a file
        # whose own header forbids it to appear there.
        with open(cfg.expected, "w") as f:
            f.write(EXPECTED_HEADER)
            for name in sorted(got):
                if name in quar:
                    continue
                f.write("%-24s %s\n" % (name, got[name]))
        print("regenerated %s (%d cells; %d quarantined and omitted)"
              % (cfg.expected, len(got) - len(quar), len(quar)))
        return 0

    want = {}
    with open(cfg.expected) as f:
        for line in f:
            line = line.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            name, _, v = line.partition(" ")
            want[name] = v.strip()

    # A cell in BOTH files is two contradictory claims about one cell — the exact
    # state the 15 hand-restored rows were in before the quarantine existed.
    for name in sorted(set(quar) & set(want)):
        qfails.append(
            "%s: IN BOTH FILES — the expected table records a verdict (%s) AND "
            "the quarantine pins a signature. A cell belongs to exactly one of "
            "them; remove the expected-table row." % (name, want[name]))

    fails = [r for n, r in sorted(hard.items()) if n not in quarantined_ok]
    fails += qfails
    for name in sorted(set(got) | set(want)):
        if name in quar:
            continue                     # owned by the quarantine, not the table
        if name not in want:
            fails.append("%s: NEW CELL, not in the expected table" % name)
        elif name not in got:
            fails.append("%s: MISSING — the expected table has it, this run did not"
                         % name)
        elif got[name] != want[name]:
            fails.append("%s: verdict changed\n    expected: %s\n    got     : %s"
                         % (name, want[name], got[name]))

    # The two BOUNDARY CONTROLS were measured above, before any mode's early
    # return; here they simply join the report.
    fails += ctlfails

    write_out(got)
    accepts = sum(1 for v in got.values() if v.startswith("ACCEPT-IDENTICAL"))
    declines = sum(1 for v in got.values() if v.startswith("DECLINE"))
    print("loop_twin_matrix [--phi-surface %s]: %d cells — %d ACCEPT-IDENTICAL, "
          "%d DECLINE, %d other; %d quarantined (pinned signatures), "
          "2 boundary controls"
          % (cfg.phi_surface, len(got), accepts, declines,
             len(got) - accepts - declines, len(quar)))
    tal = {}
    for v in got.values():
        tal[v.split("\t")[0]] = tal.get(v.split("\t")[0], 0) + 1
    for k in sorted(tal):
        print("    %-34s %d" % (k, tal[k]))
    for cn, cv in ctlgot:
        print("    control %-26s %s" % (cn, cv))
    if fails:
        print("\nFAILED (%d):" % len(fails))
        for r in fails:
            print(r)
            print()
        return 1
    print("all cells match %s; all %d quarantined cells diverge with their "
          "pinned signature (%s); both boundary controls as pinned for the `%s` "
          "surface"
          % (os.path.basename(cfg.expected), len(quar),
             os.path.basename(cfg.quarantine), cfg.phi_surface))
    return 0


EXPECTED_HEADER = """\
# loop_twin_matrix.expected.txt — the committed disposition table for
# tools/loop_twin_matrix.py (bd test_C_libtooling-8h7d.5, Rule-13 round 4).
#
# ⚠ WHICH SURFACE THIS FILE MEASURES. `--phi-surface` selects both the generated
# `cq_phi` spelling and the table pair (`SURFACE_TABLES`), and the file it wrote
# is named for that surface: the SHIPPED `void` surface (bd
# test_C_libtooling-3qlq Increment 1, the register-free branch phase) owns the
# unqualified `loop_twin_matrix.{expected,quarantine}.txt` that
# `e2e-loop-twin-matrix` reads, and the RETIRED `register` surface owns the
# `.register.txt` pair. Never diff two of these across surfaces and read the
# result as a compiler change: 156 of the 274 cells generate a DIFFERENT PROGRAM
# on each surface, because a branch phase touches no register at all.
#
# ONE LINE PER CELL, `m_<prefix>_<region>_<suffix>` — plus a fourth `_<record>`
# segment on the 36 RECORD-axis cells (bd drbq Inc 2a round-1 review), plus a
# fifth `_<rgate>` segment on the 118 CONTROLLED-Ry-ARM cells (bd drbq Inc 3,
# plus the one bd drbq Inc-4 controlled-state-prep decline control
# `m_ry_rprep_none_none_none`; their region token always starts `r`) — then its
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
#   to TRACE-DIVERGENCE cannot appear here at all — it is a hard failure, and its
#   only other home is the PINNED-SIGNATURE quarantine (see below), which is a
#   filed defect and not a blessing — and a
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
# ── bd test_C_libtooling-drbq INCREMENT 3 — 15 CELLS ARE NOT IN THIS FILE AT
#    ALL, AND THAT IS DELIBERATE (2026-09-04) ──────────────────────────
#
# The Inc-3 regeneration moved 76 of the 117 Ry-axis rows and ZERO of the 156
# pre-Inc-3 rows. FIFTEEN more cells produce `TRACE-DIVERGENCE`, which the
# paragraph below says may never be recorded here — and it must not be, because
# recording it would make this table claim that a rolled circuit differing from
# its twin is an expected outcome. They were first RESTORED to their pre-Inc-3
# `UNROLLED-ONLY` verdicts by hand, which left this file asserting a disposition
# that was no longer true and failed each cell TWICE; they now live in
# `tools/loop_twin_matrix.quarantine.txt` instead, each pinned to the EXACT
# unified-diff signature of its divergence.
#
# READ THAT FILE'S HEADER BEFORE TOUCHING IT. A QUARANTINE IS NOT A BLESSING: a
# quarantined cell passes ONLY if it still diverges in exactly the pinned way,
# and fails if the signature moves, if it stops diverging ("quarantine stale —
# remove it"), or if it appears in both files. CLASS A (6 cells, bd
# test_C_libtooling-1m5p) the hoisted loop-invariant derived chain, ROLLED
# deficient; CLASS B (21 cells, bd test_C_libtooling-a3z7) the M-C in-place vs
# out-of-place decision on a constant `a`-register op, in two directions
# depending on where the op sits — and for its suffix half the ROLLED circuit is
# the better one; CLASS C (2 cells, NO FILED ISSUE YET, bd
# test_C_libtooling-3qlq) a `-O1` mask fold that makes the two SPELLINGS
# different programs, which is a GENERATOR question and not a compiler one.
# Neither A nor B was in Increment 3's scope to fix — both are Rule-13 changes to
# subsystems it did not touch, and both would move shipped Rz goldens — and
# neither is in Increment 1's either. What each increment does is add CUSTOMERS:
# on the void surface class B went 9 cells -> 21 and class C appeared, because a
# branch phase leaves `a` loop-INVARIANT in bodies where the register spelling
# gated it, which is exactly the precondition both classes need.
#
# A CELL BELONGS TO EXACTLY ONE OF THE TWO FILES, and the gate says so out loud.
# `--regenerate` omits every quarantined cell from this table for that reason;
# when a quarantine entry is retired, delete its block and regenerate so the cell
# gets a real verdict here again.
#
# TRACE-DIVERGENCE and WARN-ASYMMETRY are NEVER recorded here. They are hard
# failures whatever this file says — a trace that differs from its twin's is the
# defect this gate exists to catch, and no table entry may bless it.
#
# REGENERATE DELIBERATELY: `--regenerate`, then state in the commit message which
# cells moved and why (Rule 12). Regeneration will not overwrite a hard failure.
"""


QUARANTINE_HEADER = """\
# loop_twin_matrix.quarantine.txt — PINNED-SIGNATURE QUARANTINE.
#
# A QUARANTINE IS NOT A BLESSING. `loop_twin_matrix.expected.txt` says, and goes
# on saying, that `TRACE-DIVERGENCE` may NEVER be recorded there as an expected
# verdict — a table entry that says "this pair may differ" retires the one gate
# in the tree that can see the F-4 class. This file does not relax that by one
# inch. It records a FILED DEFECT together with the EXACT way it manifests today,
# and it FAILS IN BOTH DIRECTIONS:
#
#   * the cell stops diverging        -> FAIL, "quarantine stale — remove it"
#   * the cell diverges DIFFERENTLY   -> FAIL, the pinned signature moved
#   * the cell is in BOTH files       -> FAIL, two contradictory claims
#   * any NON-quarantined divergence  -> FAIL, exactly as before
#
# So the only thing that passes is "these cells, diverging in exactly these
# ways". Nothing here licenses a rolled circuit to differ from its twin; it
# licenses THIS defect, in THIS shape, until its bd issue is closed.
#
# WHY THE FILE EXISTS (bd test_C_libtooling-drbq Inc 3, round-1 lens L7). The
# Inc-3 Ry-arm axis is the first place in this matrix where the ARM ROTATES A
# REGISTER THE CONDITION DOES NOT READ. That one property makes `a`
# loop-invariant in a body with no a-register gate, and `clang -O1` then treats
# the rolled and flat spellings differently in two ways that have nothing to do
# with the arm class. Both classes were reproduced BY SIGNATURE on the pre-Inc-3
# oracle binary with an `Rz` arm — 15 of 15, character for character — so Inc 3
# does not create them. It adds CUSTOMERS to them: all 15 shapes declined before
# Inc 3 and compile now. "Pre-existing" is true of the defect and false of its
# population, and both halves belong in the bd issues.
#
# The alternatives were all worse, and the reasons are worth keeping:
#   * blessing the verdict in expected.txt — retires the gate (its own charter).
#   * deleting the 15 cells — removes the only cells that can see this class on
#     the day they first saw it; the `165/174` move, making a number green by
#     changing what it measures.
#   * fixing `Uncomputation` / `ArithLowering` inside Inc 3 — two Rule-13
#     subsystems the increment did not touch, both moving shipped Rz goldens.
#   * leaving the gate permanently red — Rule 19 verbatim: a gate expected to be
#     red is a gate people stop reading, and the 16th divergence lands in a run
#     everybody already knows is red. The 8h7d.5 F-4 class was found BECAUSE the
#     gate was green and one cell went red.
#
# THE SIGNATURE is a SHA-256 digest (16 hex) of the FULL unified diff of the two
# traces, hunk headers included — not a line count, not a verdict. A divergence
# that grows, shrinks, moves position or changes opcode is a different signature
# and a RED. The `rolled`/`unrolled` lines beside it are the FIRST DIFFERING LINE
# PAIR, stored unhashed so a reader can see the defect without running anything;
# `<end>` means that side had no such line.
#
# `owner` names the subsystem AND THE DIRECTION — which side is deficient. The
# direction is the part people get wrong: for class B the ROLLED side is the
# BETTER circuit (one fewer rail, no residual entanglement), so "make the roll
# match the flat" would make the emitted circuit worse.
#
# THE TWO BOUNDARY CONTROLS ARE IN THE SCRIPT, NOT HERE (`QUARANTINE_CONTROLS`),
# and they run on EVERY invocation — plain, `--regenerate` and
# `--refresh-quarantine` alike, each of the latter two REFUSING TO WRITE while a
# control has moved: with NO REGION AT ALL the two spellings
# agree, and with the arm back ON the condition register at the same opaque
# derived threshold they agree. Those two measurements are what makes the class
# story above a claim about the compiler rather than a paragraph. If either
# control starts diverging, the entries below stop meaning what they say.
#
# THIS HEADER IS SCRIPT-OWNED. `--refresh-quarantine` rewrites the whole file
# from `QUARANTINE_HEADER` in `tools/loop_twin_matrix.py` and re-sorts the
# blocks, so ANY text hand-added up here is silently lost on the next refresh
# (round-2 review F-R2-3). A new class paragraph therefore goes in that
# constant, never in this file; the two are byte-identical by construction and
# `--refresh-quarantine` is what keeps them so.
#
# TO ADD A CELL: file a bd issue naming the owning subsystem and the direction,
# add the block by hand, then `--refresh-quarantine` to write its digest. The
# tool can neither add nor remove a cell — that is a human decision (a `cell`
# the run does not know is a hard failure, and a quarantined cell that has
# stopped diverging is "quarantine stale"; the selftest pins both).
# TO RE-PIN A CHANGED SIGNATURE: `--refresh-quarantine`, and say in the commit
# message what moved and why (Rule 12). It is exactly as deliberate as
# `--regenerate`.
# TO RETIRE ONE: when the bd issue closes, DELETE the block and `--regenerate`
# the expected table so the cell gets a real verdict again.
#
# FORMAT: blank-line-separated blocks, `#` comments, keys
#   cell / class / bd / owner / digest / rolled / unrolled — all six required.
#   `owner` is one line and deliberately short; the full root cause of each class
#   is written ONCE, here, rather than repeated 15 times.
#
# ── CLASS A — 6 cells, bd test_C_libtooling-1m5p. `oder` (the OPAQUE derived
#    condition) with no a-register gate. ROLLED IS THE DEFICIENT SIDE.
#    ⚠ ON THE VOID SURFACE THE BOUNDARY CONTROL `q_armoncond` IS AN INSTANCE OF
#    THIS CLASS rather than a bound on it — a branch phase writes no register, so
#    the control's own body satisfies the precondition below. See
#    `SURFACE_CONTROL_VERDICTS`; it is pinned by signature and it is the smallest
#    class-A reproducer in the tree.
#    With the arm on `r`, `a` is loop-invariant, so `clang -O1` LICM-hoists the
#    whole `sitofp; fadd; sqrt` chain into the preheader on the ROLLED side and
#    CSEs the two repetitions' chains on the FLAT side. The rolled form then
#    discharges the two INTERIOR rails immediately after the `sqrt` and LEAVES
#    THE TOP RAIL (`h4 = sqrt((double)a + 3.0)`) ALLOCATED. `h4` is a
#    deterministic injective function of `a`'s basis label, so the rolled circuit
#    ends in a perfect WHICH-PATH RECORD entangled with the condition register —
#    `a` is dephased for anything downstream (Rule 8's last sentence). The flat
#    form discharges all three LIFO at the end.
#    Rule-6 FORMALLY SAFE (left allocated, never freed dirty) and invisible to
#    STRICT stage 2b, whose census counts `cqrt_alloc` mints and these rails are
#    TEMPLATE-minted. Note the discharge ORDER is LIFO-INVERTED — `h3`, the
#    `sqrt`'s operand, is uncomputed and freed while `h4`, derived from it, is
#    still live — which is exactly what makes `h4` permanently undischargeable.
#    OWNER: `Uncomputation` / `FreePoint` interior placement for a chain the loop
#    does not own.
#
# ── CLASS B — 21 cells, bd test_C_libtooling-a3z7. ONE DECISION, TWO
#    DIRECTIONS: `ArithLowering`'s M-C in-place-vs-out-of-place choice for a
#    constant op on the `a` register disagrees with the rolled form's, and WHERE
#    that op sits decides whether the disagreement leaks.
#
#    (B-suffix, 17 cells) `add` in the a-register SUFFIX field, so the op feeds
#    the MEASURE. FLAT IS THE DEFICIENT SIDE.
#    Rolled emits `cqrt_addc_i32(h0, 3)` and measures `h0`; flat emits
#    `cq_template_add_i32_hl(h0, 3) -> h10` and measures `h10`. Same value, same
#    `_unc` and `cqrt_free` counts, one extra rail on the FLAT side — and `h0` is
#    then left allocated and entangled with `h10` (`h10 = h0+3` is a bijection,
#    so again a which-path record). The rolled form's add is a chain member that
#    `collapseRailPhisIn` step (3) MARKS in place; the flat form's is
#    straight-line and `ArithLowering`'s M-C G6/G7 decide.
#    ⚠ THE ROLLED CIRCUIT IS THE BETTER ONE HERE: one fewer rail, no residual
#    entanglement. The matrix's oracle is the flat twin, so for this class the
#    gate is comparing the good circuit against the worse one and calling the
#    good one the deviation. DO NOT "fix" the roll to match the flat.
#    OWNER: `ArithLowering` M-C G6/G7 versus `LoopLowering::collapseRailPhisIn`
#    step (3).
#
#    (B-prefix, 4 cells) `xor` in the a-register PREFIX field, so the op feeds
#    only the CONDITION and is dead by the measure. NEITHER SIDE IS DEFICIENT.
#    Rolled emits `cqrt_xorc_i32(h0, 9)` in place; flat emits
#    `cq_template_xor_i32_hl(h0, 9) -> h1` out of place AND THEN `_unc`s and
#    frees it, so no rail is left allocated on either side and no which-path
#    record survives. Same decision, same owner, one extra transient rail. It is
#    quarantined rather than blessed because it is still a rolled != flat gate
#    stream from one M-C disagreement, and because "harmless today" is how a
#    class earns a customer that is not (the B-suffix half of this very class).
#    MEASURED on the void surface 2026-09-05; on the `register` surface three of
#    these four were ROLLED-ONLY (the flat side declined `mixed phase/value arm`)
#    and one was ACCEPT-IDENTICAL, so this population is NEW and the void
#    surface is what exposed it.
#
# ── CLASS C — 2 cells, bd test_C_libtooling-3qlq (AWAITING AN OWNER DECISION —
#    this class has no filed issue of its own and MUST NOT be quoted as though it
#    had). `m_xor_range_{none,rz}`, and they are here because they FIT NEITHER
#    CLASS ABOVE: they carry the B-prefix disagreement AND, independently, a
#    `clang -O1` fold that makes the two sides different programs.
#    MEASURED: the rolled side emits `cqrt_xorc_i32(h0, 9)`; the flat side emits
#    `cq_template_xor_i32_hl(h0, 8)` — MASK 8, NOT 9. The region is
#    `if (a > 5 && a < 20)`, which `-O1` canonicalizes to `(x - 6) <u 14`, and
#    [6,20) is closed under a bit-0 flip because both bounds are even; so on the
#    FLAT spelling — where the second repetition's `a ^ 9` cancels the first and
#    the xor result reaches nothing but the range test — InstCombine drops the
#    low bit of the mask. In the rolled loop the xor is in place on the
#    loop-carried `a` and the low bit is genuinely live, so it cannot.
#    THE TWO SIDES HAVE STOPPED BEING THE SAME PROGRAM, which is the situation
#    this instrument's own docstring says is answered by making the immediate
#    OPAQUE (as `off` already is), not by a quarantine. Doing that changes the
#    generated source of every `xor`-prefix cell, so it is an owner decision
#    rather than a prep one, and until it is taken these two are pinned here so
#    that neither side may drift unnoticed.
#    The same phenomenon is already documented for these cells on the `register`
#    surface, where it produced a DISPOSITION mismatch instead: see
#    `loop_twin_matrix.expected.register.txt`'s note on the three `xor`/`none`
#    ROLLED-ONLY cells.
#    OWNER: the GENERATOR (`REGION["range"]` x `PREFIX["xor"]`), not the compiler.
"""


if __name__ == "__main__":
    sys.exit(main())
