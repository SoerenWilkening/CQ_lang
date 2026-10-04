/* slice_io_controlled.c — Phase 7.6 Increment 2 e2e smoke (test_C_libtooling-
   9x4z.2): the CONTROLLED Tier-0 conditional output `if(q)printf` / `if(q)putchar`.
   The only test layer that LINKS — and Increment 2 adds the NEW frozen
   hand-written core symbol `cqrt_tape_write_<W>_controlled`, so this golden is the
   ONLY proof it resolves and signature-matches against libcq_runtime (Rule 2/16;
   the .ll fixtures assert IR text and never link).

   `emit_sgt` exercises the UN-NEGATED polarity: `if (q > 5)` keeps the gate arm as
   the TRUE successor, so the controlled write fires on the flag directly (no
   `cqrt_x`). `emit_ne` exercises the NEGATED polarity: clang -O1 canonicalizes
   `if (q != 3)` to `icmp eq` with SWAPPED successors (Rule 9), so the gate arm is
   the FALSE successor and the controlled write is bracketed by a self-inverse
   `cqrt_x` pair (committing on ¬flag). Each conditional output lowers to ONE
   `cqrt_tape_write_i32_controlled(ctrl, tape, src)` — the entry is ALWAYS appended
   (classical/deterministic tape length, PRD-7.6 §2.4); only its content is gated.

   `q` is PRESERVED by the controlled write (CNOT-class) and by the flag mint/strip
   (the copy destination is the fresh kept out-rail, never q), so q stays coherent
   for the user's `cq_measure`. NO measurement is inserted by the I/O lowering (Rule
   5) — the ONLY `cqrt_measure` lines are the user's two measures; there are ZERO
   controlled rotations and ZERO `cqrt_cswap`. `noinline` mirrors slice_io (uncompute
   is gated off in `main`; -O1 would otherwise inline these away). cq_theta /
   cq_measure resolve from CQ.h, force-included; printf/putchar from stdio. */
#include <stdio.h>

__attribute__((noinline)) void emit_sgt(int seed) {
    int q = seed; cq_theta(&q, 0.5);
    if (q > 5) printf("%d", q);   /* un-negated: gate arm = TRUE successor */
    (void) cq_measure(q);
}

__attribute__((noinline)) void emit_ne(int seed) {
    int q = seed; cq_theta(&q, 0.25);
    if (q != 3) putchar(q);       /* clang -O1 -> icmp eq, FALSE arm, ¬flag bracket */
    (void) cq_measure(q);
}

int main(void) {
    emit_sgt(7);
    emit_ne(4);
    return 0;
}
