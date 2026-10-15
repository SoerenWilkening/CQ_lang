/* slice_control_cascade_three_bools.c — THE OWNER'S OWN FILE, N=3.

   `example/grover/grover_oracle_uncompute.c` (snapshot 2026-09-14) with the
   THIRD region uncommented — the live code lines verbatim, three `_Bool`s, no
   `int` workaround and no new `cq_*` function. Two harness edits only:
   `main` -> `slice`, and `_Bool b0 = 0;` for `_Bool b0;` (see the FIRED
   RETIREMENT TRIGGER at the bottom — the undef spelling was bd `z9t1`'s subject,
   and since `z9t1` landed the two spellings emit a BYTE-IDENTICAL trace).

   IT DECLINED UNTIL 2026-09-14 and the string was
       cq controlled lowering: state prep seed is proven equal to the condition
       register under quantum control
   anchored at `%1 = cq_theta_i1(i1 false, double 5.0e-01)` — which is `b0`'s
   theta, NOT the region that declined: after `-O1` the SECOND region's condition
   IS `%1` (a bare rail), and F2 anchors on `declAnchor(Region)` = the condition.

   ⚠ WHAT THE THIRD REGION COSTS, and why the two-bools slice beside this one
   compiled while this did not. `-O1` gives the b1 prep region a merge phi `%6`,
   and the THIRD region's own guard `if (a >= 3)` becomes
       %8 = select i1 %6, i32 %7, i32 %2        ; `a` after `if (b1) a -= 3`
       %9 = icmp sgt i32 %8, 2
   On the STRAIGHT-THROUGH edge of the b1 region, `f2Model` folds
   `%8 = union([-1,-1], [2,2]) = [-1,2]` — the union never reads the select's
   condition — so `%9` is provably `false` there, which IS the b1 seed. F2 read
   that as "the author might have written `b1 = cq_theta(%9, 0.5)`" and declined.

   THE FIX IS AVAILABILITY, NOT "THE SAME WIRE" (bd `om35`, owner-ruled
   2026-09-14; `ArmClassify.cpp`, the φ-descendant conjunct at F2's test). `%9`
   USES `%6`, the region's own merge phi. A value that uses the phi is available
   neither in the arm (the phi does not dominate it) nor on the pred edge
   (use-before-def), so it cannot be the register the author rotated — it did not
   exist yet at either slot. It is a witness F2 must not count; every other
   witness still counts, which is why the 29 fixtures that decline with F2's
   string all still decline and NONE of them moved.

   READ THE GOLDEN, 40 lines (35 before bd r2j3.32):
      1-2    `b0`'s rail + its Ry.                 [`if (a >= 3)` folds: a == 5]
      3-11   `if (b0) a -= 3` — the peeled `a`-mux as the rail-root CNOT-copy
             merge: copy `b0`'s basis label into a |0> ancilla `h1`, two
             X-bracketed controlled copies into a fresh |0> out rail `h2`. Its
             un-copy is DEFERRED to lines 23-29 (bd r2j3.32).
     12-14   `b1`'s rail, prepped to the seed 0, rotated UNCONDITIONALLY by 0.5
             and CANCELLED under `b0` with -0.5 — Ry ADDITIVITY, the compiler's
             spelling of an anti-control (`a >= 3` IS `b0 == 0` here). NEVER a
             `cqrt_x` on a user register. `h0` is only the CONTROL here, so the
             `a`-mux's flag `h1` (a copy of `h0`) stays valid across it.
     15-22   `if (b1) a -= 3` — the arm's chain HOISTED
             (`cq_template_add_i32_hl(h2, -3)`), then the same merge with the
             PREPPED REGISTER `h5` as the control, reading `h2` as a copy source.
     23-29   bd r2j3.32: that copy was `h2`'s last reader, so the `a`-mux is
             REVERSED — its two copies re-applied in reverse under `h1`, `h1`
             un-copied and freed, then `h2` freed at a proven |0>.
     30-31   the `b1`-select's un-copy and the free of its ancilla `h7`.
     32-36   THE THIRD REGION, THE LINE THIS SLICE EXISTS FOR. `a` is now a
             quantum rail, so the guard is minted as a real flag
             (`cq_template_icmp_sgt_i32_hl(h8, 2) -> h9`), `b2` is prepared with
             `cqrt_ry_i1_controlled(h9, h10, 0.5)` — a controlled state prep on a
             COMPARE condition — and the flag is stripped by its own `_unc` and
             freed at a proven |0>.
     37-40   the four measurements.

   ⚠ IT IS NOT A PREFIX OF THE TWO-BOOLS GOLDEN, and the difference is ORDER, not
   content. MEASURED: at N=2 the emitted order is (b1 prep, then the `a`-mux); at
   N=3 it is (the `a`-mux, then the b1 prep). Same gates, same operands, swapped
   pair — and that pair COMMUTES for the reason `CLAUDE.md` CORRECTNESS RISK §4
   already records for the N=2 stream: `h0` appears in both only as a CONTROL, so
   both blocks are block-diagonal in `h0`'s basis, and their targets are disjoint
   ({h5} against {h1,h2,h3,h4}). So no prefix gate is asserted here; asserting one
   would pin a scheduling artefact as if it were a unitary.

   THE INVARIANTS, readable straight off the golden:
     * `h0` and `h5` are the USER'S REGISTERS: each appears ONLY at arg 0 of a
       `cqrt_cnot`, as the CONTROL of `cqrt_ry_i1_controlled`, or in a measure.
       Never `cqrt_x`-bracketed, never freed.
     * every `cqrt_x` is on an ancilla (`h1`, `h7`), whose `x (+) x = 0` return is
       what makes its `cqrt_free` a proven-|0> one; the `a`-mux rail `h2` is
       freed too, after its reversal (bd r2j3.32).
     * `h9` is the third region's flag: minted, used as a control, stripped by the
       matching `_unc`, freed. One mint, one strip, one free.

   ⚠ RETIREMENT TRIGGER (L8) — IT FIRED, AND ITS PREDICTION WAS CORRECT. As
   written on 2026-09-14 this trigger said: the owner's file spells `_Bool b0;`
   UNINITIALISED; it compiles, stage 2b is identical (`9 rail mint(s) of which 7
   left allocated, 3 cqrt_free site(s): 3 verified`), and the trace differs in
   exactly ONE literal — `cqrt_alloc_i1(1)` for `cqrt_alloc_i1(0)` on line 1,
   because stage 3 materialises the `undef` seed; "when bd `z9t1` lands
   (normalize EARLY, undef-seed-is-zero-at-allocation), that difference
   disappears and the undef spelling becomes byte-identical to this golden."

   bd `z9t1` LANDED at `f28e435a`. RE-DERIVED on the rebuilt primary at
   `66428ddc` with the only edit being `_Bool b0 = 0;` -> `_Bool b0;` in a /tmp
   copy: exit 0, stderr 0 bytes, stage 2b unchanged (`9 rail mint(s) of which 7
   left allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven`),
   and the trace is now BYTE-IDENTICAL to this golden — the one-literal
   difference is GONE (`CLOSING_MEASUREMENTS.md` §4b). So the sentence "differs
   in exactly ONE literal" is HISTORY on any binary at or after `f28e435a`, and
   the two spellings are one program to this test. Do not delete this file.

   NEW TRIGGER: if that one-literal difference ever comes BACK, the first thing
   to check is `normalizeUndefRotationSeed` (`RotationLowering.cpp`) and the two
   facts its refinement rests on — the rewrite fires only on `isa<UndefValue>`,
   and `undef` is uniqued per type (bd `z9t1`, CLAUDE.md CORRECTNESS RISK §4c).
*/
#include "CQ.h"

int slice(void) {
    int a = 5;
    _Bool b0 = 0;
    _Bool b1 = 0;
    _Bool b2 = 0;

    if (a >= 3){
        cq_theta(&b0, 0.5);
    }
    if (b0) a -= 3;

    if (a >= 3){
        cq_theta(&b1, 0.5);
    }
    if (b1) a -= 3;

    if (a >= 3){
        cq_theta(&b2, 0.5);
    }

    return (int) cq_measure(b0) + (int) cq_measure(b1) + (int) cq_measure(b2)
         + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
