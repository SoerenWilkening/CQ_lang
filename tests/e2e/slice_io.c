/* Phase 7.6 reversible I/O output tape (test_C_libtooling-9x4z.1). The FIRST
   end-to-end proof of the FROZEN cqrt_tape_alloc + cqrt_tape_write_<W> ABI — the
   only layer that LINKS, so the only proof those new hand-written core symbols
   resolve and signature-match against libcq_runtime (Rule 2/16; the .ll fixtures
   assert IR text and never link).

   A theta-tainted `x` is APPENDED to the output tape twice (`printf` then
   `putchar`, the stream->tape registry minting ONE cqrt_tape_alloc and two
   cqrt_tape_write_i32 appends with DISTINCT out-handles). x is then dead and
   UNMEASURED. The kept output rails are never freed/reversed, and NO measurement
   is emitted anywhere (Rule 5 — the tape is the coherent replacement for a
   print-site measurement).

   THE SOURCE RAIL h1 IS REVERSE-PLAYED BUT NEVER FREED (bd 261j(a), owner ruling
   2026-08-10). This file asserted "the whole source lineage uncomputes through the
   Phase-5 spine (Bennett copy-out: ry adjoint + cqrt_free)" until that ruling, and
   the golden carried a final `cqrt_free(h1)`. The `cqrt_ry_i32(h1, -0x1p-1)` is
   still there and still correct; only the free was WRONG. A
   tape write is a CNOT-class copy onto a rail the reversal NEVER touches, so h1
   stays ENTANGLED with the tape, and h1's own chain is a single `cqrt_ry` whose
   only other operand is a classical angle (Rule 3) — there is no live condition
   for `Ry†` to be a permutation of, so it does not return h1 to |0>. `cqrt_free`
   is a hardware reset = a projective measurement, so the old pair was a hidden
   measurement of an entangled rail (Rules 5/6/8). Leaving h1 allocated is Rule
   6's stated fallback, not a decline: the pass still exits 0 silently.

   THE ADJOINT STAYS, AND THAT IS LOAD-BEARING, NOT COSMETIC. The freeze suppresses
   the FREE, never the reversal. Suppressing the adjoint too — the first
   implementation of this ruling — is itself a silent miscompile: a surviving
   non-frozen rail's `_unc` reads the frozen rail and needs it at its PRODUCER-TIME
   value, which only the full reverse-play restores. The Rule-13 round measured
   four independent instances of that, two of them on the QRAM surface; see
   ir-pass/test/lowering_io_tape_interleaved_rotation.ll. Applying a unitary adjoint
   to a rail we then leak is harmless, and on the kept tape it is not observable at
   all.

   THIS IS NOT A WRONG PRINTED ANSWER, and must not be quoted as one. The free is
   LOCAL to h1, so it cannot change the kept tape rails' reduced density matrix
   (no-signalling) — rho is the same either way, because the copy already mixed
   it. What was wrong is a violated hard invariant with a provably false written
   justification, inside the freeze-gating 7.6 ABI. It is also why NOTHING caught
   this for as long as it shipped: `opt -verify` is clean either way, the golden
   byte-diff cannot witness "freed at |0>" at any ABI, and stage 2b
   (free_pairing_check.py) CERTIFIED the defective free via A2-reduces-to-identity.
   The lit CHECK-NOT lines are the real regression guard until bd 261j(b) closes
   the checker hole; this golden pins the shape at the only layer that LINKS.

   `noinline` is LOAD-BEARING: whole-DAG uncompute is gated OFF in `main`, and
   -O1 would otherwise inline `emit` away so the uncompute never runs.
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
