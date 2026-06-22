/* slice_mixed_value_io.c — Phase 7.2 Increment 2 e2e smoke (test_C_libtooling-
   65wb.2): a MIXED value+I/O diamond — `if (q > 5) printf("%d", q);` plus a value
   select `r = (q>5) ? q+1 : q+2;`. clang -O1 MERGES both into ONE br-diamond (the
   printf is unspeculatable, so the diamond survives; the two value arms differ only
   by a constant, so the `add` is hoisted past the merge and the φ selects the
   CONSTANTS [1, 2]). The only test layer that LINKS — it proves the I/O controlled
   write AND the value controlled-copy data-mux resolve and signature-match against
   libcq_runtime and share ONE flag + ONE tape (Rule 2/16).

   Both effects ride the ONE flag minted from the ONE compare: the I/O effect →
   one `cqrt_tape_write_i32_controlled` (printf is the TRUE arm, so it fires on
   `flag`, no `cqrt_x`); the value effect → the 4.4 controlled-XOR copy data-mux
   (`out=|0>`; the flag-set constant 1 copied on `flag`; the ¬flag constant 2 copied
   in a self-inverse `cqrt_x` bracket), then `add q, out` (a Q+Q op) → measure. The
   tape entry is ALWAYS appended (deterministic length); only its content is gated.

   The CONSTANT data-mux is the SAFE subset (a constant carries no phase, so the XOR
   copy cannot dephase, Rule 7); a computed two-base φ declines (= the 65wb.5 exp2
   conservative decline). `q` is PRESERVED by the tape write (CNOT-class) and the
   flag mint/strip, and is read by the value path — that fan-out is safe because the
   tape write precedes the spliced value path. ZERO compiler-inserted measurement,
   ZERO controlled rotations / cswap (Rule 5). `noinline` mirrors slice_io_controlled
   (uncompute is gated off in `main`; -O1 would otherwise inline this away). */
#include <stdio.h>

__attribute__((noinline)) int emit_mixed(int seed) {
    int q = cq_theta(seed, 0.5);
    if (q > 5)
        printf("%d", q);                 /* I/O effect — TRUE arm, fires on flag  */
    int r = (q > 5) ? (q + 1) : (q + 2); /* value effect — constant data-mux + q  */
    return cq_measure(r);
}

int main(void) {
    return emit_mixed(7);
}
