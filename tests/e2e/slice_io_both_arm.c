/* slice_io_both_arm.c — Phase 7.2 Increment 2 e2e smoke (test_C_libtooling-
   65wb.2): BOTH-ARM controlled I/O `if (q > 5) printf("%d", q); else putchar(q);`.
   The only test layer that LINKS — proves the two controlled writes resolve and
   signature-match against libcq_runtime and that one function shares ONE tape
   (Rule 2/16; the .ll fixture asserts IR text and never links).

   clang -O1 keeps a br-DIAMOND (neither sink is speculatable; the two arms call
   DISTINCT sinks, so they do not fold to one printf): two single-pred sole-sink
   arms reconverging at one 2-predecessor NO-phi merge. The lowering routes BOTH
   polarities under the ONE flag minted from the ONE compare: the TRUE arm (printf)
   fires on `flag` directly (no `cqrt_x`); the FALSE arm (putchar) is bracketed by a
   self-inverse `cqrt_x` pair (committing on ¬flag, Rule 9). Each lowers to ONE
   `cqrt_tape_write_i32_controlled(ctrl, tape, src)` into the SAME tape — tape length
   is classical/deterministic (EXACTLY 2 entries; only CONTENT is gated, so the
   golden records BOTH the printf and the putchar entry where the classical program
   would have printed only one — the inactive arm commits |0> content, accepted
   Bennett-tape semantics, PRD-7.6 §2.4).

   `q` is PRESERVED by both controlled writes (CNOT-class) and by the flag mint/strip
   (the copy destination is a fresh kept out-rail, never q), so q stays coherent for
   the user's `cq_measure`. NO measurement is inserted by the I/O lowering (Rule 5) —
   the ONLY `cqrt_measure` is the user's; ZERO controlled rotations, ZERO `cqrt_cswap`.
   `noinline` mirrors slice_io_controlled (uncompute is gated off in `main`; -O1 would
   otherwise inline this away). cq_theta / cq_measure resolve from CQ.h, force-
   included; printf/putchar from stdio. */
#include <stdio.h>

__attribute__((noinline)) void emit_both(int seed) {
    int q = seed; cq_theta(&q, 0.5);
    if (q > 5)
        printf("%d", q);   /* TRUE arm  -> fires on flag (no cqrt_x bracket) */
    else
        putchar(q);        /* FALSE arm -> fires on ¬flag (cqrt_x bracket)   */
    (void) cq_measure(q);
}

int main(void) {
    emit_both(7);
    return 0;
}
