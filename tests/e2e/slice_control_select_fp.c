/* slice_control_select_fp.c — fp-DATA select un-staging e2e smoke
   (fp-data-select-PRD §8, issue test_C_libtooling-kjd1): the branchless fp
   ternary through the FULL pipeline, the only test layer that LINKS and so the
   ONLY proof that the new frozen-designate runtime symbol
   cqrt_copy_f64_controlled (§4.1, Option B) resolves and signature-matches
   against libcq_runtime (Rule 2). This is the census-motivated shape (§1):
   branchless range-reduction written as a C ternary reaches the pass as a
   `select` at -O1, and fp select now lowers instead of declining.

   SOURCE INTENT (the §5 positive, with a DERIVED true operand so the golden
   can assert the §6 uncompute shape):
       q   : tainted f64 handle (cq_theta == Ry; a real-amplitude BASIS
             superposition of fp bit patterns — no relative phase, so the
             controlled-CNOT copy of its bit-pattern label is faithful)
       t   : q + 1.0 — a theta-DERIVED tainted fp chain (fadd _hl template)
       sel = (q > 0.5) ? t : 0.25;
       measure sel

   At -O1 the ternary is a single `select i1 %c, double %t, double 2.5e-01`
   over an fcmp-ogt condition — the FIRST fcmp-minted merge: flag mint is
   cq_template_fcmp_ogt_f64_hl / strip its _inv (not the icmp family). The
   classical false operand 0.25 is materialized via cqrt_alloc_f64 (the 4.4
   carve-out extended to fp); the fp width tags only the symbol names — every
   handle stays i32 (Rule 15).

   THE §6 UNCOMPUTE ASSERTION (why this golden is load-bearing beyond linking):
   the copied source chain t = fadd(q, 1.0) is DEAD after the merge, but its
   cqrt_copy_f64_controlled user marks the DAG NotClosed (DagTraversal), so the
   theta-derived source lineage is deliberately LEAKED — the golden contains NO
   `_unc` line and EXACTLY ONE cqrt_free (the flag's). q, t, out, and the
   materialized 0.25 scratch are all LEFT ALLOCATED: out carries the answer and
   the sources are entangled with it through the copy — freeing any of them is
   a hidden measurement (Rules 6/8).

   WHY DETERMINISTIC: trace-only runtime, straight-line select (no branch);
   cqrt_measure_f64 returns 0. The golden pins the trace captured from REAL
   linked output (templates BEFORE runtime — load-bearing link order). */
double slice(void) {
    double q = 0.3;
    cq_theta(&q, 0.5);                 /* taint q -> f64 condition handle     */
    double t = q + 1.0;                /* theta-derived fp chain (leaked, §6) */
    double sel = (q > 0.5) ? t : 0.25; /* branchless fp ternary -> select     */
    return cq_measure(sel);            /* reads the copied-out answer (out)   */
}
int main(void) { (void) slice(); return 0; }
