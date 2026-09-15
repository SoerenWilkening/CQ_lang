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
    # bd 3qlq Inc 1, the SECOND C-1 review round, finding **F-C1-1**. These TWO
    # put NOTHING in the loop body — they name a line emitted in the PREHEADER
    # (`PRELOOP` below). They exist because F-C1-1 is a defect of the peel that
    # walks the rail's PRE-LOOP chain, and no axis in 284 cells put anything
    # there: `PREFIX` is body text, so its `add`/`xor` are IN-LOOP ops that M-C's
    # G5 refuses OUTRIGHT (`OutOfPlace` by construction), which is exactly why
    # the FACT-time peel was already right about them and wrong about a
    # preheader one. Used ONLY by sub-grid F — `BASE_PREFIX` below keeps the
    # 120-cell product on the five original keys, which is what makes every
    # pre-existing generated source byte-identical.
    "addpre": "",
    "xorpre": "",
    # bd 3qlq Inc 1, the FOURTH C-1 round (bd 7yd0 / OQ-C2-1 / review_inc2_r2
    # finding **F-I2-1**). Same PRE-LOOP `a = a + 7;` as `addpre`, but the
    # register it lands on is a Phase-4 CONTROL-OWNED MERGE OUT-RAIL rather than
    # a `cq_theta` root mint — see `PREHEAD` below and sub-grid F4. Used ONLY by
    # F4; `BASE_PREFIX` is unchanged, so the 120-cell product cannot see it.
    "addpresel": "",
}
# The PRE-LOOP line each PREFIX key contributes (bd 3qlq Inc 1, F-C1-1). Only the
# two `*pre` keys have one. A CONSTANT immediate, deliberately, and not the
# volatile `off` the in-body `add` uses: M-C's G4 refuses a formal-argument
# immediate and stage 2b must be able to prove the slot classical, and the
# finding's own reproducer is `q = q + 7`.
PRELOOP = {
    "addpre": "    a = a + 7;\n",
    "xorpre": "    a = a ^ 9;\n",
    "addpresel": "    a = a + 7;\n",
}
# The text emitted between the head (`int a = ...; a = cq_theta(a, 0.5);`) and
# `PRELOOP`, i.e. BEFORE the pre-loop in-place op — bd 3qlq Inc 1, the FOURTH
# C-1 round (F-I2-1). Only `addpresel` has one, and every other cell takes the
# `""` default, which is what keeps all 1144 pre-existing generated sources
# byte-identical (PROVEN by hashing them before and after, not asserted).
#
# WHAT IT BUILDS AND WHY IT HAS TO BE THIS SHAPE. The finding is the PRODUCT of
# two axes the instrument had separately: a PREHEADER in-place op (sub-grid F3)
# and an invariant root that is a CONTROL-OWNED MERGE OUT-RAIL rather than a
# root mint (pinned only in lit, by `control_phase_kickback_inloop_merge_rail.ll`,
# which has no preheader op). `a = (a > 5) ? mb : mc;` is the 4.4 tainted-
# condition SELECT merge — the ONE producer of such a rail that is expressible
# in a SINGLE translation unit, which is what this instrument is. The other two
# measured producers need something the matrix cannot spell: the Phase-4
# value-arm route needs a multi-op arm (pinned by the `q4b_preadd_*` reproducer
# pair and measured by hand), and the 6.5 classical-call arm needs a second TU.
#
# The ARMS ARE TWO SEPARATE `cq_theta` REGISTERS, deliberately. Constant arms
# (`(a>5) ? 7 : 5`) make the merge an all-`ConstantInt` one, and `-O1` then folds
# the pre-loop `+ 7` into the case constants, so the preheader op DISAPPEARS and
# the cell would silently stop being about the finding at all (MEASURED as
# `q5w_mux`/`q5v_add2`, both ACCEPT-IDENTICAL on every binary). A merge whose
# `%out` holds a NON-CONSTANT value is the population.
PREHEAD = {
    "addpresel": ("    int mb = 0, mc = 0;\n"
                  "    mb = cq_theta(mb, 0.25);\n"
                  "    mc = cq_theta(mc, 0.3);\n"
                  "    a = (a > 5) ? mb : mc;\n"),
}
# The five keys the 120-cell PREFIX x REGION x SUFFIX product iterates. Spelled
# out rather than taken from `PREFIX.keys()` so that adding a key for a sub-grid
# cannot silently multiply the long-pole gate by 48 cells (bd 3qlq Inc 1, F-C1-1).
BASE_PREFIX = ("none", "ry", "rz", "add", "xor")
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
# bd uq96 — the RECORD axis at the `i1` width, on the BARE RAIL itself. See the
# `_Bool` AXIS section below for why it is only the `premark` shape: `postmark`
# and `bodyread` say something about a register a later gate RELABELS, and in a
# bare-rail cell the only thing that could relabel `b` is a gate on the
# CONDITION's own wire — which is a documented loud decline in its own right and
# would make the cell decline for two reasons at once (the `rprep` mistake).
# `mark` is declared `_Bool`, not `int`: an `int mark = b;` is a ZEXT of a
# tainted `i1`, which lowers to a `cq_template_zext_*` rail and quietly changes
# the cell's subject from "a record of a rail" to "a cast of a rail".
RECORD_B = {
    "bpremark": {"decl": "    _Bool mark = 0;\n",
                 "pre": "        mark = b;\n", "post": "",
                 "tail": " + (int) cq_measure(mark)"},
}
RECORD_ALL = dict(RECORD, **RECORD_R, **RECORD_B)

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

# ── THE SEVENTH AXIS — THE `_Bool` (i1) CONDITION (bd uq96) ──────────────────
# OWNER RULING 2026-09-14: WIDEN THIS INSTRUMENT BEFORE THE LOOP WORK, so that
# bd wx8g's primary witness can actually witness its subject.
#
# WHAT 288 CELLS COULD NOT SEE, MEASURED BEFORE ANY CODE WAS WRITTEN (Track L,
# SCOPE_L1a §5): `grep -c -i bool tools/loop_twin_matrix.py` was **2**, and both
# were inside `phi_surface_of_header`. Every axis above builds its condition from
# the `int a` register and its arm from `int a` or `int r`, so the `i1` width was
# uncovered — and `i1` is the width of every shipped bool-controlled state prep
# and in-place Ry arm since e96f89c (bd l4x4.b), the width of the owner's entire
# Grover cascade (`tests/e2e/slice_control_cascade_two_bools.c`), and the width
# bd wx8g is about to lower INSIDE A LOOP. The only instrument in the tree that
# can see a leaked TEMPLATE-minted rail, pointed at a width it cannot express,
# reports green over cells that never exercise the subject.
#
# THE ONE STRUCTURAL DIFFERENCE, AND IT IS WHY THIS IS AN AXIS AND NOT A NARROWER
# SPELLING OF `REGION`. A `_Bool` condition is a BARE RAIL: `clang -O1` gives
# every natural `bool` spelling `br i1 %b` with NO COMPARE AT ALL, so the
# register IS the flag (CLAUDE.md CORRECTNESS RISK §1, the bare-`_Bool` row; bd
# 3qlq.4 / r9e5 / l4x4.b). Nothing is minted, nothing is stripped, and on the
# accept path there is no `cqrt_free` and no `cqrt_x` on the user register at
# all. These cells therefore do not re-run the Rz/Ry axes at a narrower width —
# they exercise a DIFFERENT LEAF of the condition grammar, the one every other
# cell in this file mints a flag for.
#
#   B_COND — how the bare rail is read.
#     `b`   the shipped leaf, `if (b)`.
#     `nb`  POLARITY, and not a re-spelling of `b` (Rule 9). `if (!b)` is the
#           ¬-arm on a RAIL, which is the one place the emitter may NOT
#           `cqrt_x`-bracket a user register: it takes the CNOT-copy ancilla
#           (`bf = cqrt_alloc_i1(0); cqrt_cnot(h_b, bf)`) or, for a diagonal arm,
#           the `rz(-θ)` spelling. A bracket appearing on `b` here is the defect.
#     `ab`  the CONDITION TREE with a rail leaf beside a compare leaf,
#           `if (b & (a == off))` — `clang -O1`: `and i1 %b, %cmp`, which
#           `collectCondTree` owns directly and `emitCondNetwork` turns into
#           `cqrt_toffoli(h_b, h_cmp, node)` with the RAIL AS A CONTROL (the flat
#           witness for the shape is `tests/e2e/slice_control_phase_bool_and.c`).
#
#           ⚠ THE SPELLING WAS MEASURED, NOT CHOSEN, AND ALL THREE READINGS ARE
#           KEPT because each records a different `clang -O1` phenomenon — this
#           is the `oeq`/`one`/`oder` lesson a second time. Measured at the
#           ORACLE f7b65d8c, phase arm, invariant carry:
#             `b & (a == off)`   ACCEPT-IDENTICAL, 22 trace lines. The BITWISE
#               `&` forces both operands to be evaluated, so the volatile load is
#               unconditional and the tree survives as `and i1`; the rolled form
#               mints and discharges a `cq_template_icmp_eq_i32_hl` rail PER TRIP
#               and is byte-identical to its twin. This is the live cell, and the
#               only bare-rail cell in the file that can see a leaked
#               TEMPLATE-minted rail (the 8h7d.5 F-4 class) at `i1`.
#             `b && a == off`    DECLINE-BOTH `nested control flow`. SHORT-CIRCUIT
#               `&&` plus a VOLATILE operand: the load may not be speculated
#               above the `b` test, so `-O1` cannot if-convert and hands the pass
#               a genuine depth-2 NEST, not a tree. Kept as sub-grid B6 — it is
#               the one cell that says a `&&` whose right operand is
#               non-speculatable is not a condition tree at all.
#             `b && a == 5`      UNROLLED-ONLY. Speculatable, so `-O1` gives
#               `select i1 %b, i1 %cmp, i1 false` and the FLAT side accepts with
#               the full `collectCondTree` stream; the ROLLED side declines the
#               GENERIC `control flow under quantum control` because `a` and `b`
#               are both loop-invariant and LICM lifts the compare out (the
#               `oeq`/`one`/`oder` hoist, verbatim, one axis over). Kept as
#               sub-grid B6: it is a recorded OVER-DECLINE with a live flat twin.
#
#   B_ARM — what fires under the bare rail. All four are SHIPPED FLAT lowerings
#     and not one of them is shipped IN A LOOP, which is exactly the diff bd wx8g
#     must produce.
#     `phi`   the branch-phase KICKBACK (Rule 7): `cqrt_rz_i1(f, θ)` on the flag,
#             no gate on any user register.
#     `ry`    the in-place controlled Ry arm on a SECOND, DISJOINT register
#             (`cqrt_ry_i32_controlled(h_b, h_r, θ)`, after which the rotated
#             register is FROZEN — Rule 6, `Ry(θ)|0⟩ ≠ |0⟩`). bd wx8g's customer
#             verbatim, and the flat twin is
#             `tests/e2e/slice_control_inplace_ry_bool_diamond.c`.
#     `prep`  the controlled STATE PREP: the arm's `cq_theta` has a CLASSICAL
#             arg-0, so the hoisted gate MINTS the rail it rotates. `r` is
#             DECLARED CLASSICAL for this arm and never seeded — unlike the
#             `rprep` decline control above, whose own comment regrets that its
#             seeded `r` makes the region a Q data mux INDEPENDENTLY of the loop.
#             Flat twin: `tests/e2e/slice_control_inplace_ry_bool_stateprep.c`.
#
#             ⚠ AND THE INTENT — "then this cell declines for ONE reason" — WAS
#             MEASURED FALSE, WHICH IS WORTH MORE THAN THE INTENT. At the ORACLE
#             f7b65d8c all five prep cells are `DECLINE-BOTH-DIFFERENT`: rolled
#             `control flow inside a loop body`, FLAT `state prep merged with a
#             quantum register`. The classical declaration buys nothing past the
#             FIRST repetition, because the flat twin is the body written out
#             TWICE and repetition 2's pred incoming is repetition 1's MERGE φ —
#             a tainted incoming, which is F1's no-cloning mux. That is
#             STRUCTURAL to a twin with TRIPS > 1 and cannot be designed away
#             here; `rprep`'s comment says the same thing one hop along.
#
#             ⚠ SO READ THESE FIVE ROWS AS A TRAP, NOT AS A TODO. The ROLLED side
#             carries the loop message, so bd wx8g will be tempted to flip them —
#             but the rolled form's own pred incoming is the header φ of `r`,
#             which is quantum after trip 1, i.e. the SAME no-cloning question
#             the flat side refuses. A flip to `ACCEPT-IDENTICAL` is impossible
#             (the flat side declines); a flip to `ROLLED-ONLY` is the
#             expected-table header's "an over-accept and a Prime-Directive red
#             however green the run looks". The passing move is `DECLINE-BOTH` on
#             the flat message.
#     `val`   the VALUE arm `a = a - 3`, which `-O1` if-converts to
#             `select i1 %b, i32 %sub, i32 %a` — the 4.4 data select on a bare
#             rail condition. It is the owner's own `if (b1) a -= 3;` line
#             (bd boi6 D-B / Track M, landed 59ac5b7), put in a loop.
#
#   B_CARRY — how `b` reaches the body, and the two are different PROGRAMS for
#     `collapseRailPhisIn`, `railPhiRootMint` and `staleRailRecordRead` rather
#     than two columns of one.
#     `binv`  seed once before the loop: the rail is LOOP-INVARIANT and its
#             header φ is the identity carry (the 8h7d.5 round-2 F-2 shape).
#     `bcar`  additionally re-rotate it per trip: `b` is LOOP-CARRIED and its
#             header φ is an `i8` WIRE — a carried `_Bool` is an `i8` in every
#             loop form, which is why bd r903 is load-bearing here (bd boi6's
#             loop-carried `bool` header φ is the same object). The theta stands
#             FIRST in the body, which is the shipped-but-unpinned accept the
#             2026-09-13 session recorded as L-0.
#
# ⚠ WHAT THIS AXIS IS BLIND TO, in the same words the Ry axis says it: the ORACLE
# is the UNROLLED twin, and the unrolled twin of a bare-rail cell is itself the
# l4x4.b FLAT lowering. A defect the flat and rolled paths SHARE is byte-identical
# on both sides and reports `ACCEPT-IDENTICAL`. The flat side's own witnesses are
# the `ir-pass/test/control_*_bool_*.ll` family and the `slice_control_*_bool_*`
# slices; nothing here replaces them.
B_COND_TEXT = {
    "b": "if (b)",
    "nb": "if (!b)",
    "ab": "if (b & (a == off))",
}
# The two compound spellings that are NOT the core product's, kept as sub-grid B6
# at the phase arm only. Each records one `clang -O1` phenomenon measured on the
# ORACLE and neither is decoration — see the `ab` paragraph above.
B6_COND_TEXT = {
    "abs": "if (b && a == off)",     # short-circuit + volatile => a genuine NEST
    "abl": "if (b && a == 5)",       # speculatable => `select i1`, then LICM
}
B_ARM_TEXT = {
    # Written in the REGISTER spelling like every other `cq_phi` site in this
    # file, so that `phi_void_source` — the ONE rewriter, applied in ONE place to
    # the finished text of both sides — is what produces the shipped `void`
    # spelling `cq_phi(M_PI);`. A hand-written void arm here would be a second
    # spelling of the surface and could drift from the rolled/unrolled pair.
    "phi": "{ a = cq_phi(a, M_PI); }",
    "ry": "{ r = cq_theta(r, 0.9); }",
    "prep": "{ r = cq_theta(7, 0.9); }",
    "val": "{ a = a - 3; }",
}
# The four arms the B1 CORE PRODUCT iterates. Spelled out rather than taken from
# `B_ARM_TEXT.keys()` for exactly the reason `BASE_PREFIX` is: B7 below ADDS arm
# keys, and a live `.keys()` here would silently multiply the long-pole gate by
# 24 cells. (It did, once, before this line existed.)
B_CORE_ARM = ("phi", "ry", "prep", "val")
B_REGION = {c + a: "        %s %s\n" % (B_COND_TEXT[c], B_ARM_TEXT[a])
            for c in B_COND_TEXT for a in B_CORE_ARM}
B_REGION.update({c + "phi": "        %s %s\n" % (t, B_ARM_TEXT["phi"])
                 for c, t in B6_COND_TEXT.items()})
# What the SECOND register is for each arm — the three-way answer `_wrap` takes.
# `quantum` seeds it with its own `cq_theta` (the in-place arm needs a live rail
# to rotate); `classical` declares `int r = 7;` and NEVER seeds it (the state
# prep's arg-0 must be classical or it is not a prep); `none` does not declare it
# at all, which is what keeps the 288 pre-existing cells' source text unchanged.
# Keyed by the ARM, not by a suffix test on the region token: a suffix test reads
# the answer off the spelling, and a future cond token ending in `ry` or `prep`
# would silently change a cell's program. The `assert` is the point — a new arm
# or a new B6 spelling must declare its second register or the module will not
# import.
_B_ARM_SECOND = {"phi": "none", "ry": "quantum", "prep": "classical",
                 "val": "none"}
B_SECOND = {c + a: _B_ARM_SECOND[a]
            for c in B_COND_TEXT for a in B_CORE_ARM}
B_SECOND.update({c + "phi": _B_ARM_SECOND["phi"] for c in B6_COND_TEXT})

# ── B7 — THE ITERATION-LOCAL RAIL (bd uq96 second pass, for bd wx8g clause (c))
#
# WHY THE FIRST 40 WERE NOT ENOUGH, measured by Track W and not by me. Every arm
# above declares its second register OUTSIDE the loop, so `r` is LOOP-CARRIED in
# all 40. bd wx8g has two halves: it RETIRES the l4x4.b in-loop carve (which is
# what flips the 9 `*_bry_*` rows) and it adds a NEW clause (c) for the
# ITERATION-LOCAL rail — a register DECLARED AND MINTED INSIDE THE BODY, which
# has no header φ at all, so `railPhiRootMint` can never claim it and `Rollable`
# was false for that shape BY CONSTRUCTION. **No cell in this file reached clause
# (c)**, i.e. the increment's central capability was unwitnessed by the one
# instrument that can see a leaked TEMPLATE-minted rail. That is the same blind
# spot uq96 closed one layer up, one layer down.
#
#   `ilry`    the ITERATION-LOCAL ROTATED BASE: `int r = cq_theta(7, 0.25);` in
#             the body — a ROOT MINT per trip — then the arm rotates it in place.
#             Clause (c2): K activations must mint K rails.
#   `ilprep`  clause (c2)'s `MintSeed = T` branch: `int r = 7;` in the body and
#             the arm's `cq_theta` mints. ⚠ THIS IS THE PREP SHAPE THAT LOWERS,
#             as opposed to the eight CARRIED `*prep*` rows above, whose flat
#             twin cannot escape F1's no-cloning mux. The two must not be read as
#             one family.
#   `il2`     TWO independent iteration-local rails in one body, each measured
#             inside it: `staleRailRecordRead`'s grouping key has no entry for an
#             iteration-local rail, and two rails from two mints are two
#             registers that must NOT interfere.
#   `ilesc`   the same rail READ AFTER THE LOOP. ⚠ THIS IS THE 19-vs-27 SHAPE and
#             it is the safety pair of the whole increment: Track W measured that
#             WITHOUT its clause (c3) the rolled form emits 19 trace lines where
#             its hand-unrolled twin emits 27, LEAKING two entangled which-path
#             rails of the condition's bits PER ACTIVATION — `opt` exit 0,
#             `opt -verify` clean and STRICT stage 2b `0 violation(s)` on all
#             four modules, because 2b counts `cqrt_alloc` sites and these rails
#             are TEMPLATE-minted. The byte-diff is the only instrument in the
#             tree that can see it, which is this file. The cell must therefore
#             report a DECLINE on the rolled side; `ROLLED-ONLY` here is not a
#             disposition mismatch to shrug at, it is that leak.
#
# THE DERIVED CONDITION IS NOT DECORATION EITHER. `(a >> i) & 1` is the ONLY
# condition kind in this family that mints a `cq_template_*` rail in the body per
# trip, so it is the only one whose per-trip chain is the SPINE's to discharge
# rather than the emitter's — i.e. the only one that can witness a MISSING SPINE
# DISCHARGE. It carries no `_Bool` at all (`B_BCOND` is False for it): the
# condition register is `a`, exactly as Track W's `w_g` uses `q`. `ddilry` adds
# the sub-grid-F POST-LOOP DIFFUSION, which is what turns a leaked per-trip rail
# from a Rule-6 leak into a WRONG UNITARY.
B_ARM_TEXT.update({
    "ilry": "{ r = cq_theta(r, 0.9); }",
    "ilprep": "{ r = cq_theta(7, 0.9); }",
    "il2": "{ r = cq_theta(r, 0.9); }",
    "ilesc": "{ r = cq_theta(r, 0.9); }",
})
B_DERIVED_COND_TEXT = {
    "d": "if ((a >> i) & 1)",
    "dd": "if ((a >> i) & 1)",          # + the post-loop diffusion, see below
}
B_REGION.update({c + a: "        %s %s\n" % (B_COND_TEXT[c], B_ARM_TEXT[a])
                 for c in ("b", "nb") for a in ("ilry", "ilprep", "il2")})
B_REGION.update({c + a: "        %s %s\n" % (t, B_ARM_TEXT[a])
                 for c, t in B_DERIVED_COND_TEXT.items()
                 for a in ("ilry", "ilesc")})
_B_ARM_SECOND.update({"ilry": "iterlocal", "ilprep": "iterlocalprep",
                      "il2": "iterlocal2", "ilesc": "iterlocalesc"})
B_SECOND.update({c + a: _B_ARM_SECOND[a]
                 for c in ("b", "nb") for a in ("ilry", "ilprep", "il2")})
B_SECOND.update({c + a: _B_ARM_SECOND[a]
                 for c in B_DERIVED_COND_TEXT for a in ("ilry", "ilesc")})
# Which regions declare the `_Bool b` CONDITION register at all. The derived
# family does not: its condition is `(a >> i) & 1` over the invariant `a`, and
# adding an unused `b` would put an `alloc`/`ry`/`measure` triple in every trace
# for nothing — noise in the one family whose traces are read for a missing
# discharge.
B_BCOND = dict({k: True for k in B_REGION},
               **{c + a: False for c in B_DERIVED_COND_TEXT
                  for a in ("ilry", "ilesc")})
assert set(B_SECOND) == set(B_REGION) == set(B_BCOND), \
    "a B_REGION key with no second-register answer or no bcond answer"
# The derived family reads the loop index, so the flat side must bind `i` — the
# same `_wrap(index=...)` path sub-grid F's per-bit regions take.
INDEXED_REGION = INDEXED_REGION + tuple(
    c + a for c in B_DERIVED_COND_TEXT for a in ("ilry", "ilesc"))
POSTLOOP_FOR_REGION["ddilry"] = "    a = cq_theta(a, 0.9);\n"
# How `b` is carried. Same `{pre, post}` shape as `RGATE` and merged into the one
# dict `sources` indexes, so there is a single gate-slot spelling (Rule 14).
BCARRY = {
    "binv": {"pre": "", "post": ""},
    "bcar": {"pre": "        b = cq_theta(b, 0.25);\n", "post": ""},
}
GATE_ALL = dict(RGATE, **BCARRY)

# ── WHAT EACH `second` KIND CONTRIBUTES, IN ONE TABLE (bd uq96 second pass) ──
# `_wrap` used to spell these inline as two `if second == ...` ternaries. The
# iteration-local kinds need FOUR slots each, not one, so the answers moved into
# a table: a kind that forgets a slot cannot compile, and a reader can see all
# six kinds side by side instead of reconstructing them from conditionals.
#
#   decl  a line in the head, BEFORE the `_Bool b` declaration
#   seed  a line in the head, AFTER `a = cq_theta(a, 0.5);`
#   pre   a line at the TOP of the loop body (after the carry gate)
#   post  a line at the BOTTOM of the loop body (before the SUFFIX)
#   tail  what the `return` additionally measures
#   scope whether each UNROLLED repetition needs its own `{ }` — see `_wrap`
#
# `none` / `quantum` / `classical` reproduce the pre-uq96 head and tail BYTE FOR
# BYTE, which `probes/source_identity.py` proves rather than asserts.
SECOND = {
    "none": {"decl": "", "seed": "", "pre": "", "post": "", "tail": "",
             "scope": False},
    "quantum": {"decl": "    int r = 0;\n",
                "seed": "    r = cq_theta(r, 0.3);\n",
                "pre": "", "post": "", "tail": " + cq_measure(r)",
                "scope": False},
    "classical": {"decl": "    int r = 7;\n", "seed": "",
                  "pre": "", "post": "", "tail": " + cq_measure(r)",
                  "scope": False},
    # ── the ITERATION-LOCAL kinds. The register is declared and minted INSIDE
    # the body and consumed INSIDE it, which is the whole point: nothing tainted
    # defined in the loop is read outside it, so clause (c3) is satisfied. `s` is
    # the classical accumulator that makes the per-trip read a real read.
    "iterlocal": {"decl": "    int s = 0;\n", "seed": "",
                  "pre": "        int r = cq_theta(7, 0.25);\n",
                  "post": "        s += cq_measure(r);\n",
                  "tail": " + s", "scope": True},
    "iterlocalprep": {"decl": "    int s = 0;\n", "seed": "",
                      "pre": "        int r = 7;\n",
                      "post": "        s += cq_measure(r);\n",
                      "tail": " + s", "scope": True},
    "iterlocal2": {"decl": "    int s = 0;\n", "seed": "",
                   "pre": "        int r = cq_theta(7, 0.25);\n"
                          "        int t = cq_theta(3, 0.125);\n",
                   "post": "        s += cq_measure(r) + cq_measure(t);\n",
                   "tail": " + s", "scope": True},
    # ⚠ THE ESCAPE. `last = r;` carries the per-trip register OUT of the loop and
    # the `return` reads it — the 19-vs-27 shape. It is the one kind here that
    # MUST decline on the rolled side.
    "iterlocalesc": {"decl": "    int last = 0;\n", "seed": "",
                     "pre": "        int r = cq_theta(7, 0.25);\n",
                     "post": "        last = r;\n",
                     "tail": " + cq_measure(last)", "scope": True},
}
#
#   B1  the CORE product: 3 bare-rail spellings x 4 arms x 2 carries        24
#   B2  the a-register gate STAR beside the three non-value arms, at `binv`  6
#   B3  the dtzb in-place VALUE gate beside the VALUE arm                    2
#   B4  the PREHEADER in-place op (the F-C1-1 axis) under a bare rail        2
#   B5  the RECORD axis at `i1`, on the rail itself                          4
#   B6  the two NON-core compound spellings, at the phase arm                 2
#   B7  the ITERATION-LOCAL rail — bd wx8g clause (c), IMPL_W §9.3 W-1..W-5  10
# 50 cells. B1-B6 (40) were the top of the 24-40 band Track L scoped
# (SCOPE_loop.md §2.6); B7 is Track W's own list, added once its landing measured
# that all 40 declare their second register OUTSIDE the loop and so none of them
# reaches clause (c). This gate is the suite's long pole at ~180-400 s, so nothing
# goes in here without a named conjunct it is the witness for.
B_ARMS_NONVALUE = ("phi", "ry", "prep")
B_A_STAR = (("ry", "none"), ("none", "ry"))
B_VALUE_A_STAR = (("add", "none"), ("none", "add"))
B_RECORD_ARM = ("ry", "prep")

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

# ── THE BANK AXIS (bd test_C_libtooling-rpkr) ───────────────────────────────
# WHY IT EXISTS, and why it had to exist BEFORE the capability it watches.
# bd `xdu2` / L-1a carves a bounded `bool b[N]` into an `[N x i32]` RAIL BANK —
# classical memory holding one quantum rail HANDLE per cell — and `SCOPE_L1a`
# §4.4 enumerates, site by site, that essentially every fence in the tree is
# SILENT on a value that arrives through a `load`: `railWireClosure`, gate 2c,
# `condProvenance`, `collectRailGates`, `markIfRailLocal`, `hasTaintedCondBranch`
# and `lowerMeasures` all fall off a `LoadInst` without a word. This instrument
# is the only one in the tree that can see a LEAKED TEMPLATE-MINTED RAIL (stage
# 2b has no `cqrt_alloc` to count), so it inherits the job of watching the bank —
# and on the day the accept lands it must already have cells pointed at the
# shape, not be widened afterwards to explain one.
#
# THAT SEQUENCING IS THE LESSON OF bd `uq96`, WHICH FAILED IT TWICE. Before uq96
# the matrix had no `i1` axis at all, so the witness of record for in-loop work
# could not see the width of the owner's entire cascade; and the first 40 `i1`
# cells still could not see the ITERATION-LOCAL rail, because every `B_ARM`
# declared its second register OUTSIDE the loop — the axis took a second pass of
# ten more cells. `CLAUDE.md`: *an instrument is only ever blind in the shape
# nobody has pointed it at yet.*
#
# WHAT A BANK CELL MEASURES, AND IT IS NOT ONE THING — THE READ SHAPE DECIDES.
# This is the axis's substance and the reason it is two-valued rather than a
# flag. `_wrap`'s unrolled twin is the SAME body text repeated with the loop
# counter `i` bound and constant-propagated, so the twin's bank subscripts are
# COMPILE-TIME CONSTANTS. What happens next is a MEASURED `-O1` fact, not a
# design choice (oracle `0e280fc6`, `probes/k_readshape.md`):
#
#   `kflat` — the bank is read back with constant subscripts. SROA then
#     scalarises the twin COMPLETELY. ⚠ SO THE TWIN OF A `kflat` CELL IS NOT A
#     BANK PROGRAM. `ACCEPT-IDENTICAL` here is the claim *"the rolled bank emits
#     byte-for-byte what the equivalent SCALAR cascade emits"* — which is exactly
#     witness W-B of `$PREV/trackI/IMPL_I.md` §4.2, and the strongest statement
#     available for this increment. It says nothing about a defect the SCALAR
#     path shares.
#
#   `kloop` — the bank is read back through a second, still-ROLLED loop over a
#     dynamic subscript, so SROA scalarises NEITHER side and the twin IS a bank
#     program. `ACCEPT-IDENTICAL` here is the narrower, different claim *"the
#     bank WRITE loop rolled emits what the bank write loop unrolled emits"*. It
#     says nothing about a defect in the PROMOTER, which fires on both sides.
#
# MEASURED on the oracle `0e280fc6`, from the GENERATED sources themselves and
# not from a hand-written lookalike — `probes/k_readshape.py` (array `alloca` /
# `getelementptr` counts in the stage-1 module):
#
#     cell                            side       alloca  gep   aggregate?
#     m_none_kprep_none_none_kflat    rolled          1    2   YES
#     m_none_kprep_none_none_kflat    unrolled        0    0   no (SROA)
#     m_none_kprep_none_none_kloop    rolled          2    4   YES
#     m_none_kprep_none_none_kloop    unrolled        1    2   YES
#     m_none_kiprep_none_none_kflat   rolled          2    4   YES
#     m_none_kiprep_none_none_kflat   unrolled        0    0   no (SROA)
#     m_none_k2b_none_none_kloop      rolled          2    4   YES
#     m_none_k2b_none_none_kloop      unrolled        2    4   YES
#
# Neither claim implies the other and neither is the unitary (Rule 2). They are
# recorded as two columns precisely so that a future reader cannot collapse them
# into one sentence about "the bank axis".
#
# TODAY EVERY CELL HERE DECLINES, and that is the axis working rather than the
# axis waiting: `kflat` cells are `UNROLLED-ONLY` (the rolled bank dies at
# `cq taint escape: tainted value stored to memory` while the scalarised twin
# lowers) and `kloop` cells are `DECLINE-BOTH` on that same string. The verdict
# strings PIN THE DIAGNOSTIC CHARACTER-FOR-CHARACTER, so the accept's arrival is
# a red that must be regenerated deliberately with a written reason (Rule 12) —
# the same instrument posture the 59 `UNROLLED-ONLY` Ry cells had before drbq
# Inc 3 flipped them, and the same one they are still read by.
K_REGION = {
    # The DESIGN TARGET: one fresh rail per trip, written to its own cell. This
    # is `$PREV/trackI/probes/w1_bank_prep_only.c`'s body verbatim.
    "kprep":  "        k[i] = cq_theta(k[i], 0.5);\n",
    # The same store inside a TAINTED-CONDITION ARM — the cascade's arm, and the
    # `MergePhiPeel` P10 `armWritesMemory` obstacle (`SCOPE_L1a` §4.4 (D)): the
    # peel refuses an arm that writes memory, and the promoter is supposed to
    # have removed the store before the peel ever looks.
    "kcond":  "        if (a > 5) k[i] = cq_theta(k[i], 0.5);\n",
    # D5, the allow-list's first complement: a bank LOAD used as a BRANCH
    # CONDITION. `SCOPE_L1a` calls this the headline silent failure if taint is
    # let across memory without the promotion — `br i1 %load` is untainted, so
    # `hasTaintedCondBranch` never fires and the ARM RUNS AS CLASSICAL CODE.
    "kread":  "        k[i] = cq_theta(k[i], 0.5);\n"
              "        if (k[i]) a = cq_theta(a, 0.25);\n",
    # D5, second complement: a bank load feeding ARITHMETIC.
    "karith": "        k[i] = cq_theta(k[i], 0.5);\n"
              "        a = a + (int) k[i];\n",
    # C2 — a TAINTED INDEX. The negative that must keep 7.5's existing string and
    # never acquire a new one of its own (`SCOPE_L1a` §6.1).
    "kidx":   "        k[a & 1] = cq_theta(k[a & 1], 0.5);\n",
    # C6 — TOTALITY. Same body as `kprep`; the BANK is over-sized (see `K_BANK`)
    # so two trips leave six cells never written and never read.
    "kover":  "        k[i] = cq_theta(k[i], 0.5);\n",
    # TWO banks in one body — the GROUPING-KEY probe, the bank mirror of
    # sub-grid B7's W-5 two-iteration-local-rails cell. `staleRailRecordRead`
    # groups per ROOT MINT and a bank rail has no root mint at all
    # (`SCOPE_L1a` §4.4 (B)), so "which rails must interfere" is an open
    # question with two allocas in front of it.
    "k2b":    "        k[i] = cq_theta(k[i], 0.5);\n"
              "        m[i] = cq_theta(m[i], 0.25);\n",
    # The `int`-cell WIDTH control. The `[N x i1]` -> `[N x i32]` TYPE REWRITE is
    # one of the three pieces Track B lands; an `int` bank needs no rewrite at
    # all, so this pair is the discriminator between "the bank works" and "the
    # type rewrite works".
    "kiprep": "        k[i] = cq_theta(k[i], 0.5);\n",
    "kicond": "        if (a > 5) k[i] = cq_theta(k[i], 0.5);\n",
}

# (cell type, DECLARED bank size, whether a second bank `m` is declared).
# The size is separate from `TRIPS` for exactly one cell — `kover`, C6 — and the
# read always covers indices `0 .. TRIPS-1`, so an over-sized bank's tail never
# reads a cell the body never wrote.
K_BANK = {
    "kprep":  ("_Bool", TRIPS, False),
    "kcond":  ("_Bool", TRIPS, False),
    "kread":  ("_Bool", TRIPS, False),
    "karith": ("_Bool", TRIPS, False),
    "kidx":   ("_Bool", TRIPS, False),
    "kover":  ("_Bool", 8,     False),
    "k2b":    ("_Bool", TRIPS, True),
    "kiprep": ("int",   TRIPS, False),
    "kicond": ("int",   TRIPS, False),
}
assert set(K_BANK) == set(K_REGION), "K_BANK and K_REGION disagree"

# The READ SHAPE rides in the `<rgate>` name slot, the way bd uq96 put the carry
# key there: it contributes NOTHING to the loop body, so its `GATE_ALL` entry is
# the empty pair and no cell's body text can depend on it.
K_READ = ("kflat", "kloop")
GATE_ALL.update({r: {"pre": "", "post": ""} for r in K_READ})

# The `a`-register gate STAR beside the design-target body: the pre-existing
# PREFIX/SUFFIX axes crossed with a bank, which is the only place this axis asks
# whether an in-place gate on a DISJOINT register interacts with a bank rail.
K_A_STAR = (("ry", "none"), ("none", "ry"), ("add", "none"))

# Every K region except `kidx` reads the loop counter, so the unrolled twin must
# bind `i` for them (see `_wrap`'s `index`). `kidx` subscripts by `a & 1` and
# would carry a dead counter, so it is deliberately left out rather than swept
# in — a dead `i` in two of twenty-one sources is the kind of harness noise that
# later reads as a shape.
INDEXED_REGION = INDEXED_REGION + tuple(k for k in K_REGION if k != "kidx")


def _bank_text(region, read):
    """(declaration, post-loop block, extra `return` terms) for one bank cell.

    ALL of a bank cell's non-body text is minted here, in ONE place, so the
    rolled and unrolled spellings cannot receive different versions of it — the
    same argument `_wrap` makes for the `surface` rewrite.
    """
    cells, size, twin = K_BANK[region]
    names = ["k"] + (["m"] if twin else [])
    # `= {0}` is deliberate and is NOT decoration: L-1a clause C1 requires a
    # constant-zero initializer, and an uninitialized `bool b[N];` is the OPEN
    # composition question with bd `z9t1` (`SCOPE_L1a` §7, R2). This axis takes
    # the ruled shape and leaves the unruled one to the increment that rules it.
    decl = "".join("    %s %s[%d] = {0};\n" % (cells, n, size) for n in names)
    if read == "kflat":
        return decl, "", "".join(" + (int) cq_measure(%s[%d])" % (n, j)
                                 for n in names for j in range(TRIPS))
    post = "    int ks = 0;\n" + "".join(
        "    for (int j = 0; j < %d; ++j) ks += (int) cq_measure(%s[j]);\n"
        % (TRIPS, n) for n in names)
    return decl, post, " + ks"


def sources(prefix, region, suffix, record="none", rgate="none",
            surface="register"):
    """(rolled, unrolled) C for one cell.

    THE SECOND REGISTER `r` APPEARS IF AND ONLY IF the region is an `RY_REGION`
    one, which is what makes the 156 pre-Inc-3 cells byte-identical to what they
    were before this axis existed (proven by diffing every generated source
    against the HEAD script, not asserted).
    """
    R = RECORD_ALL[record]
    G = GATE_ALL[rgate]
    # bd uq96: the `_Bool` axis is the THIRD region family and, like the Ry one,
    # it is recognised by which dict holds the key — never by the cell's arity or
    # by a token spelling, so adding a family can neither rename a committed cell
    # nor change another family's source text by one byte.
    if region in B_REGION:
        region_text, second = B_REGION[region], B_SECOND[region]
        bcond = B_BCOND[region]
    elif region in RY_REGION:
        region_text, second, bcond = RY_REGION[region], "quantum", False
    elif region in K_REGION:
        # bd rpkr: the BANK axis is the FOURTH region family and, exactly as the
        # `_Bool` one, it is recognised by which dict holds the key. The bank
        # declares no second register `r` and no `_Bool b` condition, so its
        # head and tail differ from a pre-rpkr cell's only by the bank text
        # `_bank_text` mints — which is `("", "", "")` for every other cell.
        region_text, second, bcond = K_REGION[region], "none", False
    else:
        region_text, second, bcond = REGION[region], "none", False
    S = SECOND[second]
    # `S["pre"]`/`S["post"]` bracket the region INSIDE the body — the
    # iteration-local mint at the top, the per-trip read at the bottom. Both are
    # `""` for every pre-uq96 kind, which is what leaves the 328 older cells'
    # body text untouched.
    body = (PREFIX[prefix] + G["pre"] + S["pre"] + R["pre"] + region_text
            + R["post"] + G["post"] + S["post"] + SUFFIX[suffix])
    return _wrap(body, second, R, surface,
                 index=region in INDEXED_REGION,
                 postloop=POSTLOOP_FOR_REGION.get(region, ""),
                 preloop=PRELOOP.get(prefix, ""),
                 prehead=PREHEAD.get(prefix, ""),
                 bcond=bcond,
                 bank=_bank_text(region, rgate) if region in K_REGION else None)


def _wrap(body, second, R, surface="register", index=False, postloop="",
          preloop="", prehead="", bcond=False, bank=None):
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
    `preloop` is its mirror — a line emitted BEFORE the loop and before the flat
    repetitions, for the SECOND C-1 review round's F-C1-1 cells; it sits OUTSIDE
    the repetition on both sides, so the two spellings cannot fold it differently
    (which is what makes its twin faithful where `addpost`'s was not).
    `prehead` sits one step EARLIER still — between the head and `preloop` — and
    is what lets sub-grid F4 (the FOURTH C-1 round, F-I2-1) re-point `a` at a
    Phase-4 merge out-rail before the pre-loop op lands on it; see `PREHEAD`.
    It too is outside the repetition on both sides.
    ALL THREE default to the pre-C-1 behaviour and every one of the 274 (then 284)
    older cells takes it — PROVEN by hashing all generated sources before and
    after each edit, not asserted.

    `surface` is the bd 3qlq `cq_phi` frontend surface. It is applied to the
    FINISHED text of both spellings, at the very end and in ONE place, so the
    rolled and unrolled sides can never be rewritten differently — which would
    turn a surface artefact into a `TRACE-DIVERGENCE` and blame the loop
    lowering for it. `register` returns the text untouched, byte for byte.

    `second` (bd uq96) is THREE-VALUED, not a flag: `"none"` declares no `r` at
    all, `"quantum"` declares and SEEDS it with its own `cq_theta` (what every
    `RY_REGION` cell has always done, and `True` used to spell), and
    `"classical"` declares `int r = 7;` and never seeds it — which is the
    controlled STATE PREP's precondition, since a prep whose arg-0 is already
    quantum is a data mux instead. `bcond` adds the `_Bool b` CONDITION register
    and its seeding rotation. Both default to the pre-uq96 behaviour, and all
    288 older cells take that default — PROVEN by hashing every generated source
    before and after the edit, not asserted (the same discipline `prehead`,
    `preloop` and `postloop` were added under).

    `bank` (bd rpkr) is the RAIL-BANK triple `(declaration, post-loop read
    block, extra return terms)` minted by `_bank_text`, or `None`. `None`
    unpacks to three empty strings and every one of the 338 pre-rpkr cells takes
    it — PROVEN the same way, by `probes/source_identity.py` over all 676
    cell/surface pairs. The read block is APPENDED to `postloop` rather than
    given a placement of its own, because `postloop` is already the one position
    that sits outside the repetition on BOTH spellings, which is the property
    that makes a bank read faithful between them."""
    S = SECOND[second]
    bdecl, bpost, btail = bank if bank else ("", "", "")
    postloop = postloop + bpost
    head = ("int slice(void){\n    int a = 0;\n" + S["decl"] + bdecl
            + ("    _Bool b = 0;\n" if bcond else "") + R["decl"]
            + "    a = cq_theta(a, 0.5);\n" + S["seed"]
            + ("    b = cq_theta(b, 0.5);\n" if bcond else ""))
    tail = "    return cq_measure(a)%s%s%s%s;\n}\n" % (
        S["tail"], " + (int) cq_measure(b)" if bcond else "", R["tail"], btail)
    rolled = (
        HDR
        + head
        + prehead
        + preloop
        + "    for (int i = 0; i < %d; ++i) {\n" % TRIPS
        + body
        + "    }\n" + postloop + tail
        + "int main(void){(void)slice();return 0;}\n"
    )
    # The unrolled twin is the SAME TEXT, dedented one level and repeated — never
    # a re-spelling. A hand-written twin that differs in any other way would make
    # a trace divergence ambiguous between "the loop lowering is wrong" and "the
    # two programs are not the same program".
    #
    # ⚠ AN ITERATION-LOCAL BODY CANNOT BE DEDENTED AND REPEATED, AND THE FIX IS
    # THE OPPOSITE OF A RE-SPELLING (bd uq96 second pass). `int r = cq_theta(...)`
    # written out TWICE in ONE scope is a REDECLARATION and `clang` rejects it —
    # the same harness artifact the RECORD axis designs around by hoisting `mark`
    # out of the loop, which an iteration-local rail may not do by definition. So
    # for `scope` kinds each repetition is wrapped in the `{ }` THE LOOP BODY
    # ALREADY IS, and the body text is then used VERBATIM, at its original
    # indentation, with no dedent at all. That is a STRONGER statement than the
    # dedented form, not a weaker one: the two sides share the body byte for byte.
    # The `i = i + 1;` stays OUTSIDE the brace, because that is where the `for`
    # puts it. Every pre-uq96 kind has `scope` False and takes the dedent path.
    if SECOND[second]["scope"]:
        one = "    {\n" + body + "    }\n"
    else:
        one = "".join("    " + l[8:] if l.startswith(" " * 8) else l
                      for l in body.splitlines(True))
    unrolled = (
        HDR
        + head
        + prehead
        + preloop
        + ("    int i = 0;\n" if index else "")
        + (one + "    i = i + 1;\n" if index else one) * TRIPS
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
    record — deliberately the plainest shape the wrapper can make. `"none"`
    rather than `False` since bd uq96 made `second` three-valued; the generated
    text is byte-unchanged, which the boundary controls' own pinned verdicts
    would have caught had it not been."""
    return _wrap(QUARANTINE_CONTROLS[name], "none", RECORD["none"], surface)


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


# ── THE HEADER CONTRACT (bd test_C_libtooling-gfsk) ─────────────────────────
# ⚠ WHAT WENT WRONG, because the fix only makes sense against it. `--regenerate`
# used to rewrite the WHOLE expected table, header included, from the
# `EXPECTED_HEADER` constant. On 2026-09-11 a human added 54 lines of Rule-13
# RULING prose to the file — the bd `b6ap` multi-phi-peel ruling, its re-derived
# unitary, the round-1 reviewer's caveat and an explicit L8 RETIREMENT TRIGGER —
# and the next `--regenerate` DELETED ALL OF IT and printed a success line. That
# is worse than a misreport: it DESTROYS EVIDENCE, and the thing it destroyed was
# a recorded decision, which is `CLAUDE.md` L7's failure mode arriving by tooling
# instead of by omission.
#
# bd uq96 recovered the paragraph into the constant and wrote a warning into the
# header saying "a new note goes in the constant, never in this file." ⚠ THAT IS
# A CONVENTION, NOT A MECHANISM, and this project's whole method is that a
# convention nobody can violate beats a convention nobody should. So:
#
#   1. Every table this script writes carries `HEADER_END_MARKER`. Everything
#      ABOVE it is the HEADER and belongs to whoever wrote it; everything below
#      is generated rows.
#   2. `--regenerate` and `--refresh-quarantine` PRESERVE the on-disk header
#      byte-for-byte. Hand-added prose survives, and the script says how many
#      lines it preserved — a silent deletion is no longer expressible.
#   3. A file that EXISTS but carries NO marker is a REFUSAL, not a guess: the
#      script cannot tell your prose from its own, so it writes nothing and
#      exits non-zero. (This is the one case that used to eat the paragraph.)
#   4. A MISSING file is seeded from the constant, which ends with the marker,
#      so the very next regeneration is already under rule 2.
#   5. After every write the file is READ BACK and its header compared to what
#      was meant to be preserved. An instrument's failure mode is to report a
#      pass (L10); this one checks its own work before it reports one.
#   6. Every PLAIN run checks the marker too, so a file that loses it is a red at
#      the gate rather than a surprise at the next regeneration.
HEADER_END_MARKER = (
    "# ==== END OF HEADER — everything BELOW this line is generated and is "
    "rewritten\n"
    "# ==== by --regenerate / --refresh-quarantine. Everything ABOVE it is "
    "PRESERVED\n"
    "# ==== byte-for-byte, including prose you add by hand (bd "
    "test_C_libtooling-gfsk).\n")


def split_header(path):
    """(header-text-including-the-marker, found_marker).

    `(None, False)` when the file does not exist. `(whole-file, False)` when it
    exists without a marker — the caller must REFUSE on that, never guess.
    """
    if not path or not os.path.exists(path):
        return None, False
    with open(path) as f:
        text = f.read()
    i = text.find(HEADER_END_MARKER)
    if i < 0:
        return text, False
    return text[:i + len(HEADER_END_MARKER)], True


def resolve_header(path, default_header):
    """(header, note, refusal). Exactly one of `header` / `refusal` is None."""
    hdr, found = split_header(path)
    if hdr is None:
        seeded = default_header + HEADER_END_MARKER
        return seeded, ("seeded %s with the script's own %d-line header, which "
                        "ends in the END-OF-HEADER marker — every later write "
                        "preserves whatever is above it"
                        % (os.path.basename(path), seeded.count("\n"))), None
    if not found:
        return None, None, (
            "REFUSED: %s has no END-OF-HEADER marker, so this run cannot tell "
            "your prose from the script's — and it will not guess.\n"
            "    %s is BYTE-UNCHANGED.\n"
            "    Insert these three lines after the last header line and before "
            "the first generated row:\n\n%s\n"
            "    Everything above them is then preserved VERBATIM by every "
            "future --regenerate / --refresh-quarantine. This path once deleted "
            "54 lines of Rule-13 ruling prose and reported success (bd "
            "test_C_libtooling-gfsk); refusing is the whole fix."
            % (path, path, HEADER_END_MARKER))
    return hdr, ("preserved %d header line(s) of %s byte-for-byte"
                 % (hdr.count("\n"), os.path.basename(path))), None


def write_preserving_header(path, header, body):
    """Write `header + body`, then READ IT BACK and prove the header survived.

    Rule 2 of the contract is only worth what its verification is worth, and an
    instrument that reports its own success without checking is the L10 failure
    mode. A mismatch raises `SystemExit`, which is loud and non-zero — never a
    printed warning beside a zero exit.
    """
    with open(path, "w") as f:
        f.write(header)
        f.write(body)
    back, found = split_header(path)
    if not found or back != header:
        raise SystemExit(
            "INTERNAL: %s was written but its header did not survive the write "
            "— %s. This is the bd test_C_libtooling-gfsk defect happening "
            "again and the file on disk is NOT trustworthy; restore it from "
            "git." % (path, "the marker is gone" if not found
                       else "%d line(s) went in, %d came back"
                            % (header.count("\n"), back.count("\n"))))


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
    """Returns the header note to print. Raises `SystemExit` on a refusal or on
    a failed read-back — this file is never rewritten on a guess (the header
    contract above; bd test_C_libtooling-gfsk)."""
    header, note, refusal = resolve_header(path, QUARANTINE_HEADER)
    if refusal:
        raise SystemExit(refusal)
    body = "\n"
    for n in order:
        rec = quar[n]
        body += "cell     %s\n" % n
        for k in ("class", "bd", "owner", "digest", "rolled", "unrolled"):
            body += "%-8s %s\n" % (k, rec[k])
        body += "\n"
    write_preserving_header(path, header, body)
    return note


def cell_name(cell):
    """THREE grammars, and the arity is what tells them apart — deliberately, so
    that adding an axis can never rename a committed cell:

      `m_<prefix>_<region>_<suffix>`                    the 120 record-free cells
      `m_<prefix>_<region>_<suffix>_<record>`           the 36 RECORD cells
      `m_<prefix>_<region>_<suffix>_<record>_<rgate>`   the 118 Ry-ARM cells,
                                                       the 50 `_Bool` cells and
                                                       the 21 BANK cells

    The Ry cells ALWAYS carry all five segments (`..._none_none` included) and
    their region token is always an `RY_REGION` one, so no name can collide with
    a shorter grammar's. The bd uq96 `_Bool` cells take the SAME five-segment
    grammar and their region token is always a `B_REGION` one (`b*`/`nb*`/`ab*`,
    disjoint from every `RY_REGION` token), with the carry key in the `<rgate>`
    slot — so adding the axis renames NOTHING. The bd rpkr BANK cells do the
    same again: a `K_REGION` token (always `k*`, disjoint from all three of the
    others) with the READ SHAPE in the `<rgate>` slot. All keep the `m_` prefix,
    so `grep -c '^m_'` still counts cells.
    """
    prefix, region, suffix, record, rgate = cell
    if region in RY_REGION or region in B_REGION or region in K_REGION:
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
#   F3  a PREHEADER in-place `add` on `a` x 2 per-bit regions                2
#   F4  the same, on a 4.4 SELECT-MERGE out-rail root x 2 per-bit regions     2
# 14 cells. Kept small deliberately: this gate is already the suite's long pole
# at ~400 s, and the population beyond these is measured in
# `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 rather than paid for on every run.
#
# ⚠ THE `register` TABLE IS NOT EXTENDED, and that is a decision rather than an
# omission. `loop_twin_matrix.expected.register.txt` is FROZEN HISTORY (see
# `SURFACE_TABLES`), and `--phi-surface register` cannot run at all against the
# shipped `include/CQ.h`: the header guard in `main` returns 2 BEFORE
# `cells_of_matrix()` is called, because the retired 15-width `cq_phi_<sfx>`
# family no longer exists in the tree. So these 10 cells are unreachable in that
# mode by construction. Anyone who reconstructs a register-surface header to
# re-run it will get 10 `NEW CELL, not in the expected table` failures — which is
# the honest report ("this table predates these cells"), not a silent pass.
#
# MEASURED DISPOSITION OF THE 10, on the C-1 fix build (`--regenerate`) and on
# the PRE-FIX SUBJECT 542d588 (by hand, four sampled cells + the record pair):
# NINE are `ACCEPT-IDENTICAL` here and were `TRACE-DIVERGENCE` on 542d588 — i.e.
# nine of the ten new cells would have been HARD FAILURES before the C-1 fix,
# which is what the axis is for. The tenth, `m_none_pbitd_none_rpremark_rypost`,
# is `UNROLLED-ONLY cq loop lowering: rail record read past an in-place gate on
# the same rail` on BOTH binaries — a LOUD decline of the rolled side, joining
# the 23 cells that already carry that verdict, and unmoved by this fix.
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
# ── F3 — THE PREHEADER IN-PLACE OP (bd 3qlq Inc 1, the SECOND C-1 review round,
# finding **F-C1-1**) ───────────────────────────────────────────────────────────
#
# WHAT THE 284 CELLS COULD NOT SEE, AND WHY IT IS A PRE-LOOP AXIS. Sub-grid F
# closed C-1's own shape, and the review that followed it found the shape ONE
# LINE AWAY: `a = a + 7;` in the loop's PREHEADER put the leak straight back
# (rolled 3 mints / 0 `_unc` against a hand-unrolled twin at 3/3, on 542d588 AND
# on the round-1 C-1 fix). No cell in the instrument could express it: `PREFIX` is
# BODY text, and an in-body `add`/`xor` is refused OUTRIGHT by M-C's G5 — which is
# exactly why the FACT-time peel was already right about those and wrong about a
# PREHEADER one. The defect lived in the ONE position the product had no slot for.
#
# TWO CELLS: the `add` op x the diffusing and non-diffusing per-bit regions, at
# the `rypost` carry (a `cq_theta` on `r`, which is what makes the loop MIXED and
# sends it down the `Collapsed` branch). `pbitd`'s post-loop diffusion is what
# turns a leaked bit rail from a leak into a different unitary; `pbit` is its
# control.
#
# ⚠ `xorpre` IS EXCLUDED, AND THE EXCLUSION IS MEASURED (Rule 11 — the two
# stage-1 modules were read, not reasoned about). It is an UNFAITHFUL TWIN for a
# reason that belongs to `clang -O1` and to the `xor` opcode, not to the lowering:
# `xor` DISTRIBUTES over a bit test, so on the FLAT side `-O1` rewrites
# `((a ^ 9) >> i) & 1` to `and %a, 2` / `and %a, 4` for every bit where the mask
# is 0 — creating uses of the PRE-xor register that the ROLLED side structurally
# cannot have, because its shift amount is a loop variable. The pre-op value then
# has a later read on the flat side ONLY, so M-C correctly goes OUT of place there
# (`cq_template_xor_i32_hl(h0, 9) -> h2`, and the flat side even MEASURES `h2`)
# while the rolled side emits `cqrt_xorc_i32(h0, 9)`. `add` does not distribute
# over a bit test, which is exactly why `addpre` IS faithful. MEASURED with
# `--regenerate`, which REFUSED TO WRITE and reported both `xorpre` cells as
# TRACE-DIVERGENCE with that as the first differing line; and the same artefact
# makes the PLAIN-C `q ^= 9` pair unfaithful too — its ROLLED trace still moves
# 3 mints/0 `_unc` -> 3/3 under this round's fix, but its twin cannot witness it
# (`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.10). The `xorpre` PREFIX/PRELOOP keys are
# KEPT so the claim can be re-tested by adding one token to the tuple below.
#
# ⚠ WHAT THESE CELLS DO **NOT** REACH, said here because F-C1-7 is a DOC finding
# about exactly this. The instrument is SINGLE-TU, so finding F-C1-2's ONWARD
# shape — whose invariant register is a 6.5 classical-call-arm `%out` rail — needs
# a second translation unit and is OUT OF THE MATRIX'S REACH by construction; it
# is pinned in lit (`control_phase_kickback_mixed_onward{,_r1open}_inloop.ll`) and
# at e2e (`e2e-phase-onward-perbit-loop-mixed-twin-identical`, over
# `run_slice_multi.sh`). Nor does the OUT-OF-PLACE half of F-C1-1 appear here: it
# needs a later read of the PRE-op value, which the `RECORD` axis spells only for
# values the loop itself produces; it is pinned by
# `control_phase_kickback_mixed_preheader_add_outofplace_leak_control.ll`.
F_PRELOOP_PREFIX = ("addpre",)
F3_REGION = ("pbit", "pbitd")

# ── F4 — THE PRODUCT: A PREHEADER IN-PLACE OP ON A **MERGE OUT-RAIL** ROOT
# (bd 3qlq Inc 1, the FOURTH C-1 round — bd 7yd0 / OQ-C2-1 / review_inc2_r2
# finding **F-I2-1**) ─────────────────────────────────────────────────────────
#
# F3 above closed the PREHEADER axis on a `cq_theta` ROOT MINT. The review that
# followed found the defect one axis over, and it is the same lesson a further
# time: the tree had BOTH halves and never their PRODUCT. Six
# `control_phase_kickback_mixed_preheader_*.ll` fixtures pin the preheader op
# (all theta roots); `control_phase_kickback_inloop_merge_rail.ll` pins the merge
# out-rail root (no preheader op); F3's two cells are theta roots. Crossing them
# leaked: on `main` a3c1513 these two cells are **TRACE-DIVERGENCE** (rolled 2
# per-bit mints / **0** `_unc` against a hand-unrolled twin at 2/2), and on this
# round's build they are **ACCEPT-IDENTICAL**. Cause: `hasOneUse` is structurally
# false for a merge out-rail (the emitters WRITE it before anything reads it), so
# `commitOutOfLoopInPlaceOps` refused, the peel stopped at the `add`, and clause
# (ii-b) never saw the root — while M-C converted that same op in place anyway
# (`cqrt_addc_i32(%out, 7)` IS in the emitted stream). See that function's header.
#
# TWO CELLS, the diffusing and non-diffusing per-bit regions at the `rypost`
# carry, exactly mirroring F3 so the two sub-grids differ in ONE thing: whether
# `a` is a root mint or a merge out-rail. `pbitd`'s post-loop diffusion is what
# turns the leaked bit rails from a Rule-6 leak into a different unitary.
#
# ⚠ ONLY THE 4.4 SELECT MERGE IS EXPRESSIBLE HERE. The population is "merges
# whose `%out` holds a NON-CONSTANT value": the Phase-4 value-arm route needs a
# multi-op arm (measured by hand on the `q4b_preadd_{rolled,unrolled}` pair —
# `main` 4 mints/0 `_unc` at 57 lines vs 4/4 at 65, this build IDENTICAL 65=65)
# and the 6.5 classical-call arm needs a SECOND TRANSLATION UNIT, which this
# single-TU instrument cannot spell. The 4.5 switch data-mux is measured OUT of
# the population entirely — its arms are all `ConstantInt` by C1, so `-O1` folds
# any classical op on the merge into the case constants and no preheader op
# survives (`q5w_mux`, ACCEPT-IDENTICAL on every binary). That is also why
# `PREHEAD`'s arms are two `cq_theta` registers and not two literals.
F4_PREFIX = ("addpresel",)
F4_REGION = ("pbit", "pbitd")


def f_cells():
    """The mixed-loop sub-grid (bd 3qlq Inc 1, CLEARANCE C-1, and its review
    round's F-C1-1). See `F_*` above."""
    out = [("none", g, "none", "none", rg)
           for g in F_REGION for rg in F_RGATE]
    # F2 — a record of the INVARIANT register and one of the CARRIED register,
    # at the region that also diffuses. `premark`/`rpremark` are read AFTER the
    # loop, which is where a stale record shows.
    out += [("none", "pbitd", "none", k, "rypost")
            for k in ("premark", "rpremark")]
    # F3 — the PREHEADER in-place op on the invariant register.
    out += [(p, g, "none", "none", "rypost")
            for p in F_PRELOOP_PREFIX for g in F3_REGION]
    # F4 — the same op, on a 4.4 SELECT-MERGE out-rail root (F-I2-1).
    out += [(p, g, "none", "none", "rypost")
            for p in F4_PREFIX for g in F4_REGION]
    return out


def bool_cells():
    """The `_Bool` (i1) sub-grids (bd uq96). See the SEVENTH AXIS block above.

    50 cells. Every one carries the five-segment name with a `B_REGION` token, so
    no committed cell is renamed and `grep -c '^m_'` keeps counting cells.
    """
    out = []
    # B1 — the CORE product. Every bare-rail spelling x every arm x both carries,
    # with no a-register gate: the plainest shape in which the width is exercised
    # at all, and the one a reader writes.
    out += [("none", c + a, "none", "none", k)
            for c in B_COND_TEXT for a in B_CORE_ARM for k in BCARRY]
    # B2 — the a-register gate STAR beside the three NON-value arms, at the bare
    # `if (b)` and the invariant carry. `a` is a THIRD register here (the arm
    # rotates `r`, or nothing), so these cells ask whether a non-diagonal gate on
    # a DISJOINT rail counts against the condition — which is the kjd1 gate-2c
    # window guard's known non-wire-awareness, the exact phenomenon that made 72
    # of the Ry axis's first 109 cells inert.
    out += [(p, "b" + a, s, "none", "binv")
            for a in B_ARMS_NONVALUE for p, s in B_A_STAR]
    # B3 — the dtzb in-place VALUE gate beside the VALUE arm. `ry` on `a` is
    # deliberately absent for the same reason sub-grids B and C of the Ry axis
    # leave it out: it is a non-diagonal gate on a register this arm WRITES, and
    # that is a different question from the one these cells ask.
    out += [(p, "bval", s, "none", "binv") for p, s in B_VALUE_A_STAR]
    # B4 — the PREHEADER in-place op (the F-C1-1 axis) under a bare rail: an
    # invariant `a` carrying a pre-loop `a = a + 7` beside a CARRIED second
    # register, which is the `collapseRailPhisIn` -> `Collapsed` dispatch C-1
    # lived in, now reached through a condition that mints no flag.
    out += [("addpre", "b" + a, "none", "none", "binv") for a in ("ry", "phi")]
    # B5 — the RECORD axis at `i1`, on the RAIL ITSELF: `_Bool mark = b;` taken
    # before the region and read after the loop. `staleRailRecordRead` groups per
    # ROOT MINT, and a bare-rail condition is the one shape where the record's
    # root and the CONDITION's root are the same rail — so this is where a
    # grouping-key change (bd wx8g owes one for the iteration-local spelling)
    # becomes visible.
    out += [("none", "b" + a, "none", "bpremark", k)
            for a in B_RECORD_ARM for k in BCARRY]
    # B6 — the two compound spellings the core product does NOT use, at the
    # cheapest arm. They are here because each is a MEASURED `clang -O1`
    # phenomenon rather than a shape: `abs` (`&&` with a non-speculatable
    # volatile operand) is handed to the pass as a NEST and declines on both
    # sides; `abl` (`&&` with a literal, hence speculatable) becomes the
    # `select i1` tree, accepts FLAT and is LICM-hoisted out of the rolled loop —
    # a recorded OVER-DECLINE with a live twin. Deleting either would leave the
    # `ab` core product looking like the only reading there is.
    out += [("none", c + "phi", "none", "none", "binv") for c in B6_COND_TEXT]
    # B7 — the ITERATION-LOCAL rail (bd wx8g clause (c)). 10 cells, and the split
    # is Track W's own (IMPL_W §9.3 W-1..W-5) rather than mine, because the
    # increment knows which of its conjuncts each shape reaches.
    #   W-1 (4) the rotated base at both polarities and both carries — clause
    #           (c2), "K activations must mint K rails".
    #   W-2 (2) the same with the PREP arm, at both carries — clause (c2)'s
    #           `MintSeed = T` branch, the prep shape that LOWERS.
    #   W-3 (2) the DERIVED condition, without and with the post-loop diffusion —
    #           the only family that mints TEMPLATE rails in the body, hence the
    #           only one that can see a missing SPINE discharge, clause (c3)'s
    #           subject.
    #   W-4 (1) the same rail READ AFTER THE LOOP — the 19-vs-27 shape.
    #   W-5 (1) TWO iteration-local rails in one body — the grouping-key probe.
    out += [("none", c + "ilry", "none", "none", k)
            for c in ("b", "nb") for k in BCARRY]
    out += [("none", "bilprep", "none", "none", k) for k in BCARRY]
    out += [("none", c + "ilry", "none", "none", "binv")
            for c in B_DERIVED_COND_TEXT]
    out += [("none", "dilesc", "none", "none", "binv")]
    out += [("none", "bil2", "none", "none", "binv")]
    return out


def bank_cells():
    """The RAIL-BANK sub-grids (bd test_C_libtooling-rpkr). See the BANK AXIS
    block above the `K_*` tables for what this axis can and cannot witness.

    21 cells, inside `SCOPE_L1a` §6.3's measured 16-24 band. Every one carries
    the five-segment name with a `K_REGION` token and a `K_READ` read shape, so
    no committed cell is renamed and `grep -c '^m_'` keeps counting cells.
    """
    out = []
    # K1 — the CORE product: the design target, the tainted-condition arm that
    # writes memory, and the two D5 allow-list complements, each at BOTH read
    # shapes. The read shape is crossed rather than picked because the two make
    # DIFFERENT claims (see the axis block) and a cell that carries only one of
    # them would let a reader quote the wrong one.
    out += [("none", r, "none", "none", rd)
            for r in ("kprep", "kcond", "kread", "karith") for rd in K_READ]
    # K2 — the `int`-cell WIDTH control, at the two regions that lower.
    out += [("none", r, "none", "none", rd)
            for r in ("kiprep", "kicond") for rd in K_READ]
    # K3 — the a-register gate STAR at the design target. `kflat` only: the star
    # asks about a DISJOINT register's in-place gate, and the read shape is
    # orthogonal to that question — crossing it would buy three duplicate
    # answers at the price of the suite's long pole.
    out += [(p, "kprep", s, "none", "kflat") for p, s in K_A_STAR]
    # K4 — the CARVE controls: C2's tainted index and C6's over-sized bank.
    out += [("none", r, "none", "none", rd)
            for r in ("kidx", "kover") for rd in K_READ]
    # K5 — TWO banks, the grouping-key probe.
    out += [("none", "k2b", "none", "none", rd) for rd in K_READ]
    return out


# ── THE NON-VACUITY FLOOR — the half of this axis that is not a disposition ──
# ⚠ THE BANK'S WORST FAILURE IS A TRACE THAT IS TOO SHORT, AND `ACCEPT-IDENTICAL`
# CANNOT SEE ONE. `SCOPE_L1a` §4.4 (D) measures the hole precisely:
# `cq_measure(b[i])` on an UNTAINTED load takes `MeasureLowering.cpp`'s classical
# split and emits **no gate, no symbol and NO TRACE LINE**. If that happens it
# happens to BOTH spellings, the two traces stay byte-identical, and every
# comparison in this file reports green while the user's measurement has silently
# vanished. That is `CLAUDE.md` L10's `m_none_pbitd_none_premark_rypost` lesson
# from the other side — *a cell whose two halves agree because BOTH are wrong is
# precisely what `ACCEPT-IDENTICAL` cannot see* — and the answer there was that
# only a FENCE can see it. This is that fence, inside the instrument.
#
# THE NUMBERS ARE DERIVED FROM THE PROGRAM, NOT CHOSEN. Every bank cell's source
# measures `a` once and each written bank cell once, so an accepting trace owes
# at least `1 + TRIPS * <banks>` `cqrt_measure_` lines; and each of those
# registers is a distinct rail, so it owes at least that many `-> h` mints. They
# are LOWER bounds on purpose — a cell that emits more (a flag rail, a template
# rail, the `kread`/`karith` extra rotation) is not the failure this guards
# against. `_floor_is_a_lower_bound` asserts the derivation against the generated
# source at import time, so a future edit that deletes a measurement from the
# program cannot leave the floor behind pointing at it.
def _bank_floor(cell):
    _, region, _, _, _ = cell
    banks = 2 if K_BANK[region][2] else 1
    return (1 + TRIPS * banks, 1 + TRIPS * banks)


BANK_FLOOR = {cell_name(c): _bank_floor(c) for c in bank_cells()}


def _floor_is_a_lower_bound():
    """Every bank cell's floor must be >= the number of `cq_measure` CALL SITES
    in its generated source, and the `kloop` shape must be STRICTLY greater
    (its read loop is one call site executed TRIPS times). A floor that fell
    below the call-site count would be satisfiable by a trace that has already
    dropped a measurement."""
    for cell in bank_cells():
        name = cell_name(cell)
        rolled, _ = sources(*cell, surface="void")
        sites = rolled.count("cq_measure(")
        assert BANK_FLOOR[name][0] >= sites, (
            "%s: floor %d < %d cq_measure call sites — the floor cannot see a "
            "dropped measurement" % (name, BANK_FLOOR[name][0], sites))


_floor_is_a_lower_bound()


def trace_floor(side):
    """(cqrt_measure lines, rail mints) for one side's trace. `counts()` already
    owns the mint count and is CALLED rather than re-spelled (Rule 14)."""
    return side.trace.count("cqrt_measure_"), counts(side.trace)[2]


def cells_of_matrix():
    """The full cell list: the 120-cell PREFIX x REGION x SUFFIX product with no
    record, plus the 36-cell record sub-grid (see `RECORD_GRID_*`), plus the
    118-cell controlled-Ry-arm sub-grids (see `RY_*`, whose sub-grid E2 is the
    bd drbq Inc-4 controlled-state-prep decline control), plus the 10-cell
    MIXED-LOOP sub-grid F (see `F_*` — bd 3qlq Inc 1, the Rule-13 CLEARANCE
    finding C-1, the axis 274 cells did not have, plus its review round's F3
    PREHEADER cells for F-C1-1 and the fourth round's F4 MERGE-OUT-RAIL cells
    for F-I2-1), plus the 50-cell `_Bool` sub-grid (see `B_*` and `bool_cells` —
    bd uq96, owner-ruled 2026-09-14 to land BEFORE the in-loop bool work; its
    B7 sub-grid is bd wx8g clause (c)'s ITERATION-LOCAL rail), plus the 21-cell
    RAIL-BANK sub-grid (see `K_*` and `bank_cells` — bd rpkr, landed BEFORE
    bd xdu2 / L-1a's accept for the same reason uq96 landed before wx8g).
    359 cells.

    The sizes are ASSERTED, not commented: this gate costs ~2 minutes of the
    suite's ~130-230s band and an axis edit that silently doubles it should stop
    the run, not surprise the next person to time it.
    """
    base = [(p, r, s, "none", "none") for p, r, s
            in itertools.product(BASE_PREFIX, REGION, SUFFIX)]
    rec = [(p, r, s, k, "none") for p, r, s, k
           in itertools.product(RECORD_GRID_PREFIX, RECORD_GRID_REGION,
                                RECORD_GRID_SUFFIX,
                                [k for k in RECORD if k != "none"])]
    ry = ry_cells()
    f = f_cells()
    b = bool_cells()
    k = bank_cells()
    assert (len(base), len(rec), len(ry), len(f), len(b), len(k)) \
        == (120, 36, 118, 14, 50, 21), \
        "sub-grid sizes moved: %d/%d/%d/%d/%d/%d" % (
            len(base), len(rec), len(ry), len(f), len(b), len(k))
    cells = base + rec + ry + f + b + k
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
        # (0) THE NON-VACUITY FLOOR, asked FIRST and of BOTH sides (bd rpkr).
        # It is first because every other verdict below is a COMPARISON, and a
        # comparison of two traces that both lost the same line is green. It is
        # asked of both sides even though the identity check would make one
        # enough, so that re-ordering these clauses cannot silently halve it.
        # See `BANK_FLOOR`. Cells without a floor (every pre-rpkr cell) skip it
        # entirely, so no committed verdict moves.
        floor = BANK_FLOOR.get(name)
        if floor:
            thin = [(w, trace_floor(s), s) for w, s
                    in (("rolled", rolled), ("unrolled", unrolled))
                    if trace_floor(s)[0] < floor[0]
                    or trace_floor(s)[1] < floor[1]]
            if thin:
                rep = ["%s: VACUOUS ACCEPT — the trace is BELOW the floor this "
                       "program owes." % name,
                       "  owed: >= %d cqrt_measure_ line(s) and >= %d rail "
                       "mint(s) (1 for `a` + %d per bank cell)"
                       % (floor[0], floor[1], TRIPS)]
                for w, (m, h), s in thin:
                    rep.append("  %-8s: %d measure(s), %d mint(s) over %d line(s)"
                               % (w, m, h, len(s.trace.splitlines())))
                rep.append(
                    "  ⚠ A MEASUREMENT THAT WAS NEVER EMITTED IS INVISIBLE TO "
                    "EVERY COMPARISON IN THIS FILE: `cq_measure` of an UNTAINTED "
                    "value takes MeasureLowering's classical split and emits no "
                    "gate, no symbol and no trace line (SCOPE_L1a §4.4 (D)), and "
                    "it does that to BOTH spellings at once. That is what this "
                    "floor exists to catch and it may never be blessed by a "
                    "table row or by the quarantine.")
                return "VACUOUS-ACCEPT", "\n".join(rep)
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
    # ⚠ A HARNESS THAT REPORTS A PASS ON NO INPUT IS A HOLE, NOT A PASS. Six
    # measured instances of that shape landed in this tree in ONE session
    # (`CLAUDE.md` L10): a vacuity checker printing `checked 0` over 29 real
    # negatives, an injection matrix printing `0 mutations, MISSED 0` when given
    # no fixture, a 0-byte `.ll` ACCEPTing through the passthrough early-out. So
    # an empty cell list exits NON-ZERO here rather than printing a tidy
    # "0 cells — all match".
    if not cells:
        print("REFUSED: cells_of_matrix() produced NO cells. A matrix with no "
              "subject witnesses nothing, and reporting that as a pass is the "
              "hole this line exists to close.")
        return 2
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
        try:
            note = write_quarantine(cfg.quarantine, quar, sorted(quar))
        except SystemExit as e:
            print(str(e))
            return 1
        print("re-pinned %d quarantined signature(s) in %s"
              % (len(quar), cfg.quarantine))
        print("    %s" % note)
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
        # THE HEADER IS RESOLVED BEFORE ANYTHING IS WRITTEN (bd gfsk). A file
        # with no END-OF-HEADER marker is a REFUSAL — the one case that used to
        # silently eat 54 lines of Rule-13 ruling prose and report success.
        header, note, refusal = resolve_header(cfg.expected, EXPECTED_HEADER)
        if refusal:
            print(refusal)
            return 1
        # QUARANTINED CELLS ARE NOT WRITTEN TO THE EXPECTED TABLE. The two files
        # make two different claims and a cell may be in exactly one of them —
        # otherwise the next `--regenerate` writes `TRACE-DIVERGENCE` into a file
        # whose own header forbids it to appear there.
        body = "".join("%-24s %s\n" % (name, got[name])
                       for name in sorted(got) if name not in quar)
        try:
            write_preserving_header(cfg.expected, header, body)
        except SystemExit as e:
            print(str(e))
            return 1
        print("regenerated %s (%d cells; %d quarantined and omitted)"
              % (cfg.expected, len(got) - len(quar), len(quar)))
        print("    %s" % note)
        return 0

    # RULE 6 OF THE HEADER CONTRACT (bd gfsk): the marker is checked on EVERY
    # plain run too, so a table that loses it is a red HERE — at the gate, with
    # the whole suite watching — rather than a surprise at the next
    # regeneration, which is when it would eat something.
    for label, path, const in (("expected table", cfg.expected, EXPECTED_HEADER),
                               ("quarantine", cfg.quarantine, QUARANTINE_HEADER)):
        _h, _found = split_header(path)
        if _h is not None and not _found:
            qfails.append(
                "%s (%s) has NO END-OF-HEADER marker. `--regenerate` / "
                "`--refresh-quarantine` will REFUSE to write it until the marker "
                "is restored, and until then nobody can tell hand-written prose "
                "from generated rows (bd test_C_libtooling-gfsk). Insert:\n%s"
                % (label, path, HEADER_END_MARKER))

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
# ⚠ THIS HEADER IS YOURS TO WRITE IN, AND THAT IS NEW — READ THIS BEFORE
# BELIEVING ANY OLDER COPY OF THE SENTENCE IT REPLACES (bd
# test_C_libtooling-gfsk, 2026-09-15).
#
# HISTORY, because the rule only makes sense against it. `--regenerate` used to
# rewrite this whole file from the `EXPECTED_HEADER` constant in
# `tools/loop_twin_matrix.py`, header included — so the 54-line `b6ap` paragraph
# below, hand-added to this TABLE on 2026-09-11, was DELETED by the first
# regeneration after it, under a success message, and had to be recovered from
# `git show`. bd uq96 moved the paragraph into the constant and wrote a warning
# here saying a new note goes in the constant and NEVER in this file. That was a
# CONVENTION, and a convention is not a mechanism.
#
# WHAT IS TRUE NOW. Every line ABOVE the END-OF-HEADER marker at the bottom of
# this header is PRESERVED BYTE-FOR-BYTE by `--regenerate`; only the rows below
# it are rewritten, and the script prints how many header lines it preserved. A
# copy of this file with NO marker is REFUSED outright — the script will not
# guess which half is yours, so it writes nothing and exits non-zero. Prose you
# add up here now survives; the constant is only the SEED for a file that does
# not exist yet. ⚠ Do not delete the marker.
#
# ⚠ 2026-09-11, bd `test_C_libtooling-b6ap` (THE MULTI-PHI MERGE PEEL) — FIVE
# CELLS MOVED, `DECLINE-BOTH-DIFFERENT` -> `UNROLLED-ONLY`, and the reason is
# written here rather than left to a `git blame`. The cells are the `m_rz_*_rz`
# family: `m_rz_{der,eq0,eq,gt,range}_rz`, i.e. a `cq_phi` PREFIX, a phase region,
# a `cq_phi` SUFFIX. Only the UNROLLED side moved, and it moved DECLINE -> ACCEPT;
# the ROLLED side's `condition predates a non-diagonal gate` is unchanged on both
# binaries, so the divergence is a rolled-side OVER-DECLINE, not a new defect.
#
# MECHANISM, measured. In the UNROLLED spelling `clang -O1` SINKS the second
# repetition's `cq_phi` calls into the merge block, and what it leaves behind is
# TWO `double` ANGLE phis there:
#     %5 = phi double [ 1.250000e-01, %arm ], [ -1.250000e-01, %entry ]
#     %6 = phi double [ 0x400921FB54442D18, %arm ], [ 1.250000e-01, %entry ]
# `phaseAngleTail` refuses a SECOND phi, so `classifyPhaseKickback` returned
# NotApplicable and the whole program declined `control flow`. The peel turns both
# into `select`s, the merge ends EMPTY, the region lowers as a flat kickback, and
# each peeled ANGLE select is claimed by `classifyAngleSelect`'s **Rz stem** —
# the shipped drbq Inc-2b / 3qlq Inc-1 P2 KICKBACK PAIR, NOT the kjd1 fp DATA
# merge. There is no `cqrt_alloc_f64` in any of the five outputs; the f64/angle
# wire is not crossed, because `SelectClassify`'s gate 3 makes that partition for
# a peeled select exactly as it does for a source-written one.
#
# UNITARY, re-derived by hand on `m_rz_eq_rz` and identical in form for the other
# four (6 `cqrt_rz_i1` gates each, stage 2b `0 violation(s), 0 unproven`):
#     a == 5 :  PI + (-0.125) + 0.125 + PI = 2*PI
#     a != 5 :        (-0.125) + 0.125     = 0
# which is the source's 2*PI relative phase (the two UNCONTROLLED `cq_phi(0.125)`
# / `cq_phi(-0.125)` are GLOBAL phases and are deleted by owner decision D2).
#
# The lit fixture for the same shape, written from hand IR, is
# `ir-pass/test/control_peel_angle_tail_datamux.ll`; its one-phi containment
# control is `control_peel_angle_tail_unchanged_control.ll`.
#
# ⚠ CAVEAT FROM THE RULE-13 ROUND-1 REVIEW (2026-09-11, §6), and it is the reason
# these five rows are a RULING and not a rubber stamp. The reviewer re-derived
# `m_rz_eq_rz` from scratch out of `tools/loop_twin_matrix.py`'s own
# `sources('rz','eq','rz', surface='void')` — not from the implementation notes —
# confirmed the unitary above and UPHELD `UNROLLED-ONLY` (the rolled-side
# over-decline is the established class for it: 63 other cells carry that verdict,
# three of them the same `m_rz_*_none` family one axis over). What the ruling adds:
#
#   THE PEEL IS NOW A SECOND, NON-OBVIOUS CUSTOMER-GENERATOR FOR THE ANGLE-SELECT
#   PATH, AND THAT PATH'S ACCEPT CLASS IS NARROWER THAN THE DATA PATH'S —
#   CONSTANT arms only for the Ry stem (the Inc-2b clearance narrowing), ONE
#   consumer, and the `2^-40` rounding fence. Every boundary the reviewer probed
#   declines loudly through the peel exactly as it does for a source-written
#   select (`f02` angle-AND-data, `f03` two consumers, `f05` Ry run-time arm,
#   `f07` quantum-derived angle), so the generator is FENCED TODAY. But a future
#   widening of `classifyAngleSelect` now has a customer source that does not
#   appear in its own file, its own fixtures, or any `-O1` C twin.
#
# Read these five rows as the tripwire for that: if a later increment widens the
# angle-select accept class, re-derive them rather than regenerating them.
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
# ── bd uq96 — THE 40 `_Bool` (i1) CELLS, AND WHAT THEIR FIRST TABLE SAYS
#    (owner ruling 2026-09-14: widen this instrument BEFORE the loop work) ────
#
# Their region token is a `B_REGION` one — `b*` / `nb*` / `ab*` — and their fifth
# segment is the CARRY (`binv` invariant, `bcar` loop-carried), not an `RGATE`.
# They are here because 288 cells emitted TWO `bool` tokens in total, both inside
# `phi_surface_of_header`, while `i1` is the width of every shipped
# bool-controlled prep and in-place Ry arm (bd l4x4.b, e96f89c) and of the
# owner's whole Grover cascade. See the SEVENTH AXIS block in
# `tools/loop_twin_matrix.py` for the shapes and for what each spelling was
# measured to do.
#
# MEASURED COMPOSITION AT THE 2026-09-14 SESSION ORACLE f7b65d8c — i.e. BEFORE bd
# wx8g exists, which is the whole point of regenerating an axis early (the Ry
# axis's own precedent at 1bdaa60): a table written after the implementation can
# only say the implementation agrees with itself.
#
#    9  ACCEPT-IDENTICAL — and every one of the nine is a `phi` (branch-phase
#       KICKBACK) cell: the bare rail `if (b)`, the negated `if (!b)` and the
#       bitwise tree `if (b & (a == off))`, at BOTH carries, with an a-register
#       `ry` gate and with the preheader `add`. These rows are NEW CAPABILITY
#       BEING PINNED, not new capability arriving: the rolled bare-`_Bool` phase
#       region already shipped and had NO fixture, NO slice and NO matrix cell
#       (the 2026-09-13 session recorded it as L-0). Read `m_none_abphi_*` in
#       particular — the rolled form mints and discharges a
#       `cq_template_icmp_eq_i32_hl` rail PER TRIP (22 trace lines, byte-identical
#       to its twin), so it is the first cell in this file that can see a leaked
#       TEMPLATE-minted rail under a bare-rail condition.
#   15  UNROLLED-ONLY — 9 on `cq controlled lowering: control flow inside a loop
#       body under quantum control` (EVERY `ry` arm: the in-place controlled Ry on
#       a disjoint register), 5 on `cq loop lowering: loop-carried tainted value
#       crosses iterations` (the `val` arm, `LoopLowering`'s X1 clause, reached
#       BEFORE detection), and 1 on the generic `cq controlled lowering: control
#       flow under quantum control` — `m_none_ablphi_none_none_binv`, the B6
#       short-circuit-with-a-LITERAL cell, whose flat twin accepts with the full
#       `collectCondTree` stream and whose rolled side loses its compare to LICM.
#       ⚠ THE FIRST NINE ARE bd wx8g's SUBJECT, ROW FOR ROW. Flipping them to
#       ACCEPT-IDENTICAL is that increment working; any other flip is not.
#   11  DECLINE-BOTH-DIFFERENT — 8 `prep` cells (rolled: the loop message; flat:
#       `state prep merged with a quantum register`) and 3 `val` cells at the
#       CARRIED bool. READ THE `prep` NOTE IN `B_ARM_TEXT` BEFORE ACTING ON THOSE
#       EIGHT: their flat side declines for a reason a twin with TRIPS > 1 cannot
#       avoid, so the only passing flip is to `DECLINE-BOTH`, and a flip to
#       `ROLLED-ONLY` is the over-accept this table's own note calls a
#       Prime-Directive red however green the run looks.
#    5  DECLINE-BOTH — the `ab` TREE at the `ry` and `prep` arms (4 cells, the
#       generic `control flow`: a condition TREE is off-pattern for the rail
#       ladder even where the bare rail is admitted), and the B6 cell
#       `m_none_absphi_none_none_binv`, `nested control flow` — a `&&` whose right
#       operand is a VOLATILE load cannot be if-converted, so `-O1` hands the pass
#       a genuine depth-2 nest rather than a tree.
#
# ZERO of the 40 diverge. That is a measurement and not a reassurance: the same
# run reports exactly the 29 pre-existing quarantined divergences and no more, so
# the `i1` width adds no member to class A, B or C today.
#
# ── bd uq96 SECOND PASS — THE 10 ITERATION-LOCAL CELLS (B7), AND THE ONE THING
#    A READER MUST KNOW ABOUT THEIR ROWS ───────────────────────────────────────
#
# `m_none_{b,nb}ilry_none_none_{binv,bcar}`, `m_none_bilprep_none_none_{binv,bcar}`,
# `m_none_{d,dd}ilry_none_none_binv`, `m_none_dilesc_none_none_binv`,
# `m_none_bil2_none_none_binv`. They exist because Track W's landing MEASURED that
# all 40 of the first `_Bool` cells declare their second register OUTSIDE the
# loop, so `r` is loop-CARRIED in every one and NONE of them reaches bd wx8g's
# clause (c) — the ITERATION-LOCAL rail, which is that increment's central new
# capability. See the B7 block in `tools/loop_twin_matrix.py` for what each of
# W-1..W-5 is the witness for.
#
# ⚠ THE ROWS BELOW WERE MEASURED ON THE ORACLE f7b65d8c, WHICH DOES NOT HAVE
# CLAUSE (c). That is deliberate and it is this file's standing practice — the Ry
# axis was regenerated at 1bdaa60 BEFORE Inc 3 for the same reason: a table
# written after the implementation can only say that the implementation agrees
# with itself. So these ten rows are a table of DECLINES, and THE DIFF THEY
# PRODUCE WHEN bd wx8g LANDS IS THE WITNESS.
#
# MEASURED STARTING VERDICTS, ORACLE f7b65d8c:
#     9  UNROLLED-ONLY — the flat side lowers each per-block repetition as the
#        shipped l4x4.b straight-line form; the ROLLED side declines. EIGHT of
#        the nine decline `control flow inside a loop body under quantum
#        control`, i.e. on the fence bd wx8g removes.
#        ⚠ THE NINTH IS `m_none_ddilry_none_none_binv` AND ITS MESSAGE IS
#        DIFFERENT: `condition predates a non-diagonal gate`. Its post-loop
#        diffusion `a = cq_theta(a, 0.9)` is a non-diagonal gate on the
#        CONDITION's own wire, so gate 2c refuses it BEFORE the loop clause is
#        ever reached. Lifting the loop fence alone will NOT flip that row, and a
#        reader planning the regeneration must not count it with the other eight.
#     1  DECLINE-BOTH-DIFFERENT — `m_none_dilesc_none_none_binv`, the ESCAPE:
#        rolled the loop message, FLAT `nested control flow`.
#
# ⚠ THEREFORE bd wx8g's LANDING OWES A REGENERATION OF EXACTLY THESE TEN ROWS,
# and the expected direction was written here so the diff would be CHECKED rather
# than rubber-stamped. Predicted from Track W's own measured probe table (IMPL_W
# §1, the subject binary: `w_d`/`w_b2`/`w_g`/`w_k` all ACCEPT and all
# BYTE-IDENTICAL to their per-block twins):
#     the EIGHT loop-message rows -> ACCEPT-IDENTICAL (clause (c) working: the
#         rolled form mints K rails for K activations and matches its per-block
#         twin byte for byte);
#     `m_none_ddilry_none_none_binv` -> UNMOVED, unless something also changed
#         gate 2c — if it flips, the reason is NOT clause (c) and must be found;
#     `m_none_dilesc_none_none_binv` -> UNMOVED. Its rolled side must go on
#         declining; its flat side declines for its own `-O1` reason.
#
# ━━━ WHAT ACTUALLY HAPPENED — bd wx8g LANDED 2026-09-14 AND THIS IS THE MEASURED
#     OUTCOME. The three bullets above are HISTORY; read them for what they got
#     right AND for the one reason that was wrong. Measured at the merge gate of
#     2026-09-14 on `cq-opt` `5c6f7490a81c7505…` (all six branches merged), 338
#     cells, 41 moved; full per-group adjudication in
#     `docs/prd/phase-04-swap-route-control/inc1-records/
#      session-2026-09-14-orchestrator/MERGE_TWIN_ADJUDICATION.md`.
#
#   (1) OF THE EIGHT PREDICTED LOOP-MESSAGE ROWS, **FIVE** FLIPPED to
#       ACCEPT-IDENTICAL: `m_none_bilry_none_none_binv`,
#       `m_none_nbilry_none_none_binv`, `m_none_bilprep_none_none_binv`,
#       `m_none_dilry_none_none_binv`, `m_none_bil2_none_none_binv`.
#
#   (2) ⚠ **THREE DID NOT, AND THEY ARE A SURVIVING OVER-DECLINE** —
#       `m_none_bilry_none_none_bcar`, `m_none_nbilry_none_none_bcar`,
#       `m_none_bilprep_none_none_bcar` stay `UNROLLED-ONLY / control flow inside
#       a loop body` (re-measured directly: rolled DECLINEs, flat ACCEPTs, all
#       three). THE BLOCKER IS THE COMBINATION AND THIS AXIS PAIR ISOLATES IT:
#       `bcar` re-rotates the CONDITION rail in the body (`b = cq_theta(b,0.25);`
#       every trip), so the condition register is loop-carried and moves every
#       activation, while clause (c) covers the iteration-local TARGET rail. That
#       the two are separable is measured, not argued —
#       `m_none_bry_none_none_bcar` (same carried condition, NO iteration-local
#       target) DID flip. What survives is exactly *iteration-local target rail
#       × in-body-rotated condition rail*. Over-decline => a defect to remove
#       (owner 2026-09-11), filed; do not read these three rows as a fence.
#
#   (3) ⚠ **`m_none_ddilry_none_none_binv` FLIPPED, AND THE PREDICTION'S REASON
#       WAS WRONG.** It is now ACCEPT-IDENTICAL. The cause was found, as the
#       bullet demanded: **Track W alone**, and already present in Track W's
#       ROUND-2-CLEARED binary `40edde36` — not in the three post-clearance
#       edits (a 2385-module sweep of `40edde36` vs `d47297cf` gives 0 verdict
#       differences and one GAINED source location).
#         THE STATED GROUND — "its rolled side declines at gate 2c, not at the
#       loop fence … so gate 2c refuses it BEFORE the loop clause is ever
#       reached" — IS SIMPLY FALSE, and the disproof was on the row the whole
#       time: **if 2c were the operative refusal it would refuse the FLAT
#       spelling too, and the flat side ACCEPTED on the ORACLE.** 2c never
#       stopped the rolled side; the loop carve-out did, and lifting the carve-out
#       lifted it. This is L7 in its exact shape — a wrong reason that reached a
#       right prediction, hardening by repetition until something forced it to be
#       checked. It is BENIGN: rolled and flat traces are byte-identical at 28
#       lines, STRICT stage 2b clean on both, so the rolled spelling merely
#       caught up with the twin the ORACLE already accepted. NO gate-2c ruling is
#       owed; the corrected sentence was.
#
#   (4) NINE FURTHER CELLS FLIPPED THAT NO BULLET ABOVE COVERS, ALL ON THE
#       `*bry*` AXIS (`m_addpre_bry_none_none_binv`, `m_none_bry_*` ×5,
#       `m_none_nbry_none_none_{binv,bcar}`, `m_ry_bry_none_none_binv`). NOT a
#       surprise in the compiler — a GAP IN THIS PREDICTION: it was written for
#       the second pass's ten `il*` cells and never covered the FIRST pass's
#       `*bry*` axis (`c12a2afe`), although that axis is bd wx8g's headline
#       capability (the in-loop bare-`_Bool` controlled-Ry arm). All nine are
#       ACCEPT-IDENTICAL, i.e. the rolled trace was byte-diffed against the
#       unrolled one. **Lesson for the next early-regenerated axis: a prediction
#       must enumerate every axis the landing touches, not only the axis the
#       regeneration added.**
#
#   (5) `m_none_dilesc_none_none_binv` -> **UNMOVED, as predicted.** The safety
#       pin of the increment held; see the paragraph below, which still stands
#       word for word.
#
#   (6) NOT PREDICTED BY THIS FILE AT ALL, because it is a different landing:
#       **18 cells moved in the DECLINE direction on bd `3d8q`'s stale-reader
#       ruling** (owner 2026-09-14) — 17 `UNROLLED-ONLY (rail record read past an
#       in-place gate)` -> `DECLINE-BOTH-DIFFERENT` (the FLAT side stops
#       accepting) and `m_none_pbitd_none_premark_rypost`
#       `ACCEPT-IDENTICAL` -> `DECLINE-BOTH`. Every one carries the RECORD axis,
#       i.e. a `mark = a;` whose name the wire then moves past, so
#       `cq_measure(mark)` measured the ROTATED register while naming the
#       pre-rotation state. The last of them is the instructive one: a cell whose
#       two halves were IDENTICAL because both were wrong is precisely what
#       `ACCEPT-IDENTICAL` cannot see, and only a fence can.
#
# ⚠ AND THE ESCAPE CELL IS THE SAFETY PIN OF THE WHOLE INCREMENT, SO READ IT
# LITERALLY — INCLUDING WHAT IT DOES NOT DO. `ROLLED-ONLY` on
# `m_none_dilesc_none_none_binv` — the rolled side accepting where its twin
# declines — IS clause (c3) gone, and clause (c3) gone is the 19-vs-27 leak: two
# entangled which-path rails of the condition's bits left allocated PER
# ACTIVATION, at `opt` exit 0, `opt -verify` clean and STRICT stage 2b
# `0 violation(s)` (2b counts `cqrt_alloc` sites and those rails are
# TEMPLATE-minted). A `TRACE-DIVERGENCE` here is the same thing. Both are reds
# that no table entry and no quarantine may bless.
#     WHAT IT IS NOT: a TRACE witness. Track W's 19-vs-27 pair is HAND-WRITTEN IR
#     (`trackW/probes/ir/il_{escape,noescape}_{rolled,flat}.ll`) whose flat side
#     ACCEPTS at 27 lines; this cell's flat side is `clang -O1` on two `{ }`
#     repetitions that both write `last`, and it declines `nested control flow`
#     for a reason that has nothing to do with the leak. So this row pins the
#     DISPOSITION — "the rolled side still refuses" — and the hand-IR pair keeps
#     the trace. Do not quote this cell as if it measured 19 against 27.
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
# ⚠ THIS HEADER IS YOURS TO WRITE IN, AND THAT CHANGED ON 2026-09-15 (bd
# test_C_libtooling-gfsk). It USED to be script-owned: `--refresh-quarantine`
# rewrote the whole file from `QUARANTINE_HEADER` in
# `tools/loop_twin_matrix.py`, so any text hand-added up here was silently lost
# on the next refresh (round-2 review F-R2-3) — the same defect that deleted 54
# lines of Rule-13 ruling prose from the EXPECTED table and reported success.
# Now every line ABOVE the END-OF-HEADER marker at the bottom of this header is
# PRESERVED BYTE-FOR-BYTE, only the blocks below it are rewritten, and a copy of
# this file with no marker is REFUSED rather than guessed at. A new class
# paragraph may go here or in the constant; the constant is the SEED for a file
# that does not exist yet, and the two are no longer kept byte-identical.
# ⚠ Do not delete the marker.
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
