/* Phase 7.6 reversible I/O output tape (test_C_libtooling-9x4z.1). The FIRST
   end-to-end proof of the FROZEN cqrt_tape_alloc + cqrt_tape_write_<W> ABI — the
   only layer that LINKS, so the only proof those new hand-written core symbols
   resolve and signature-match against libcq_runtime (Rule 2/16; the .ll fixtures
   assert IR text and never link).

   A theta-tainted `x` is APPENDED to the output tape twice (`printf` then
   `putchar`, the stream->tape registry minting ONE cqrt_tape_alloc and two
   cqrt_tape_write_i32 appends with DISTINCT out-handles). x is then dead and
   UNMEASURED, so the whole source lineage uncomputes through the Phase-5 spine
   (Bennett copy-out: ry adjoint + cqrt_free, AFTER the tape captured the value).
   The kept output rails are never freed/reversed, and NO measurement is emitted
   anywhere (Rule 5 — the tape is the coherent replacement for a print-site
   measurement). `noinline` is LOAD-BEARING: whole-DAG uncompute is gated OFF in
   `main`, and -O1 would otherwise inline `emit` away so the uncompute never runs.
   cq_theta resolves from CQ.h (force-included); printf/putchar from stdio. */
#include <stdio.h>

__attribute__((noinline)) void emit(int seed) {
    int x = cq_theta(seed, 0.5);
    printf("%d", x);
    putchar(x);
}

int main(void) {
    emit(4);
    return 0;
}
