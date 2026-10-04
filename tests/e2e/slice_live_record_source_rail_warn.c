/* slice_live_record_source_rail_warn.c — THE M-A GUARD AS A WARNING, END TO END
   (owner ruling 2026-08-29, bd test_C_libtooling-lyyf; M-A Increment 7b).

   THE PROGRAM IS THE CANONICAL NON-LIFTABLE RESIDUE, and it is ordinary C:

       int q = cq_theta(u, 0.5);
       int w = q * 2;
       int c = q * 3;
       cq_theta(&w, 0.25);       <-- the chained, non-diagonal Ry
       return cq_measure(w) + cq_measure(c);

   `w` and `c` are both basis records of `q`, and the second rotation acts on
   `w`, so the record standing at the gate is `q`'s OWN SOURCE RAIL, reached as
   an ANCESTOR of the rotated wire. That is the one record no uncompute can ever
   lift (bd memory [mb-source-rail-never-liftable-2026-08-29], measured): the
   rail carries the `cqrt_ry` that MINTED the superposition, `c = 3q` survives as
   a record of it, and `Ry† C Ry |0>` is not `|0>`. `preservesBasisUnderRecord`
   refuses `cqrt_ry` for exactly that reason, so M-B keeps the rail as a BORROWED
   parent — read-only, never adjointed, never freed — forever. There is no
   spelling of this program in which the M-B spine helps.

   SO IT IS THE PROGRAM THE RULING IS ABOUT. Until Increment 7b it DECLINED with
   "cq rotation lowering: non-diagonal gate over a live derived record" and `opt`
   exited non-zero; the ruling is that a leftover-record dephasing is the user's
   own circuit — "we can always apply any unitary operation we want … it is the
   user's fault to have produced a badly functioning code" (Rule 17) — so the
   compiler now emits the circuit and SAYS SO.

   WHAT THIS SLICE WITNESSES THAT A LIT FIXTURE CANNOT. It is the only layer that
   LINKS: it proves the module `opt` hands back after a warning is a complete,
   well-formed program whose every emitted symbol resolves and signature-matches,
   and that it runs. A `DS_Warning` leaves `opt`'s exit code at ZERO, so
   `run_slice.sh`'s `set -e` does not trip and the trace below is produced
   normally.

   THE WARNING ITSELF IS NOT IN THE GOLDEN, and that is a real gap worth naming
   rather than papering over: the harness diffs the RUNTIME TRACE (the slice
   executable's stdout) against `.expected.log`, while the diagnostic is `opt`'s
   STDERR at stage 2, which nothing compares. So this file pins "the program
   lowers, links and runs", and the WARNING TEXT is pinned at the lit layer
   (ir-pass/test/lowering_reject_live_record_*.ll, all 25 of them, each with a
   `WARN` prefix reading the pass's stderr).

   TWO warnings are printed, not one, and that is the shape of the module rather
   than a double report: `slice` has external linkage so it survives, and `main`
   carries an INLINED copy of it, so the pass sees the same chained rotation in
   two functions and reports each. Only main's copy executes, which is why the
   trace below shows one sequence.

   RAIL LIVENESS, which is the physics the trace does show: ONE cqrt_alloc_i32 —
   h0, the register — with h1 = h0 << 1 and h2 = 3*h0 as template rails off it.
   NOTHING is freed: h0 is a borrowed parent the spine may not touch, and h1/h2
   are both measured. Stage 2b reports "2 rail mints of which 2 left allocated,
   0 cqrt_free sites" (it counts `cqrt_alloc_*` mints, one per function) — a
   LEAK, which is Rule 6's fallback and NOT a violation. A free of any of them
   here WOULD be the hidden measurement Rule 6 forbids, and none is emitted.

   THE SECOND cqrt_ry_i32 IS THE DEPHASED ONE. h0 is allocated and entangled with
   h1 when it fires; that is exactly what the warning reports, and exactly what
   the ruling says to compile anyway. */

int slice(int u) {
    int q = u; cq_theta(&q, 0.5);
    int w = q * 2;
    int c = q * 3;
    cq_theta(&w, 0.25);
    return cq_measure(w) + cq_measure(c);
}
int main(void) { (void) slice(1); return 0; }
