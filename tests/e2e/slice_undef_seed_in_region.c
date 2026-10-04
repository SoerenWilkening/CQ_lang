/* slice_undef_seed_in_region.c — bd z9t1 customer C2b: an UNINITIALIZED
   `_Bool` prepared UNDER QUANTUM CONTROL. The second of the two spellings the
   owner ruled must compile on 2026-09-14 ("both codes are supposed to compie!!
   also no warnings").

   ON THE 2026-09-13 ORACLE THIS PROGRAM WAS A LOUD DECLINE —

       cq controlled lowering: state prep seed does not match the merge incoming
       under quantum control

   — F1's first sub-clause: the state-prep seed must be a `ConstantInt` or
   `ConstantFP`, and an `UndefValue` is neither (measured, DIAG_2026-09-14.md
   Q2 row ii, probe `u2.c`).

   *** THIS SLICE IS WHY THE RULE IS STATED OVER THE OBJECT AND NOT OVER THE
   OPERAND. *** `clang -O1` spells the uninitialized `b1` as `undef` at BOTH of
   its reads — the theta's arg-0 AND the merge phi's straight-through incoming:

       %3 = call i1 @cq_theta_i1(i1 undef, double 5.0e-01)
       %6 = phi i1 [ %3, %2 ], [ undef, %0 ]

   Normalize the seed alone and F1's SECOND sub-clause (the Pred incoming must be
   pointer-identical to the seed) fails on `i1 false` vs `undef`, so the program
   STILL declines with the same string. Both reads are the same uninitialized
   object, both are refined to the same concrete zero, and only then do the two
   edges agree.

   THE CIRCUIT, and it is the same one the owner's `grover_oracle_uncompute.c`
   gets for `bool b1 = 0;` — this file is that program with the initializer
   REMOVED, and the only line of the stream that moves is the seed's. The `b1`
   prep is the drbq `StatePrep` kind on a fresh |0> rail; because `clang -O1`
   canonicalises the guard so the ARM is the FALSE successor (Rule 9) and a
   negated controlled Ry has no diagonal escape, it is spelled by ADDITIVITY:
   `cqrt_ry_i1(h1, 0.5)` unconditionally, then
   `cqrt_ry_i1_controlled(h0, h1, -0.5)` to cancel it on the `b0 == 1`
   component. Then the peeled `a`-mux as the rail-root CNOT-copy select merge,
   whose one `cqrt_free` is a proven-|0> one.

   Both prepared rails are LEFT ALLOCATED on purpose (Rule 6: `Ry(θ)|0> != |0>`,
   so a rail that is not provably |0> is never freed), which is what STRICT stage
   2b reports as "left allocated" rather than as a violation.

   lit twin: `control_accept_undef_theta_seed_stateprep.ll` (this file's `-O1`
   `main`, verbatim). Uncontrolled sibling: `slice_undef_seed_uncontrolled.c`.
   Probe of record: `$SES/trackU/probes/u2.c`.

   Body in `slice()`, `main` returns 0 — the house convention for this
   directory. */
#include "CQ.h"

int slice(void) {
    int a = 5;
    bool b0 = 0;
    bool b1;
    if (a >= 3) { cq_theta(&b0, 0.5); }
    if (b0) a -= 3;
    if (a >= 3) { cq_theta(&b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}

int main(void) {
    (void) slice();
    return 0;
}
