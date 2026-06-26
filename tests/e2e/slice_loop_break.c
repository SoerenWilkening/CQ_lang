/* slice_loop_break.c — Phase 7.4 Increment 2 (epic y05j.2). A classically-bounded,
   DATA-MUTATING loop with a SINGLE tainted-condition value-arm early `break`,
   measured after the loop:

       int q = cq_theta(seed, 0.25);
       for (int i = 0; i < n; i++) {
           q = q ^ 5;                  // in-place value mutation (the rail)
           if ((q & 1) == 0) break;    // TAINTED value-arm break
       }
       return cq_measure(q);

   `clang -O1` fuses the tainted break flag and the classical loop bound into one
   `select(%brk, true, %bound)` exit (PRD-7.4 §1.1). 7.4 recognizes the value-arm
   break, collapses the rail to ONE in-place handle (`cqrt_xorc_i32(h, 5)`), strips
   the loop terminator to the CLASSICAL bound (so the rolled loop runs its FULL
   trip count — the break is realized VIRTUALLY, no measurement, PRD §2.9), and
   emits the index-gated copy-not-move CAPTURE + whole-loop REVERSE-PLAY:

     * forward body (× n): `fire = brk ∧ (idx==0)` (toffoli) → `cqrt_copy_i32_
       controlled(fire, h, R)` (rail INTACT) → `idx ⊕= fire ? i+1 : 0`, with every
       per-iteration scratch (the `idx==0`/`idx==i+1` eq-flags, `fire`, the `i+1`
       materialiser, the break-cond `_unc`) uncomputed + freed IN iteration —
       O(1) carried = rail + R + idx;
     * exit: `idx==0` consolidation (never-broke ⇒ full-trip value) + `cqrt_copy_i32
       (R, out)` copy-out + the consolidation reverse;
     * a BACKWARD-counted companion loop (× n) replaying the per-iteration adjoint
       `C†` (un-capture, un-write idx, recompute the break-cond to uncompute `fire`,
       inverse rail-mut) — returns R/idx/rail to their pre-loop state, disentangling
       `out` — then `cqrt_free(R)`/`free(idx)`.

   The bound `n` is a RUNTIME parameter (the harder shape: clang keeps the zero-trip
   guard + the exit merge phi), passed a fixed 4 so the trace is deterministic.
   ZERO measurements inserted; the rail is left allocated (Rule 6 — a dirty rail is
   never freed); `out` carries the disentangled break answer the measure consumes.
   `noinline` keeps the function boundary. cq_theta/cq_measure resolve from CQ.h. */
__attribute__((noinline))
int run(int seed, int n) {
    int q = cq_theta(seed, 0.25);
    for (int i = 0; i < n; i++) {
        q = q ^ 5;                  /* in-place value rail self-update */
        if ((q & 1) == 0)           /* tainted value-arm break flag */
            break;
    }
    return cq_measure(q);
}
int main(void) { (void) run(3, 4); return 0; }
