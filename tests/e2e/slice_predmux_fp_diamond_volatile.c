/* slice_predmux_fp_diamond_volatile.c — W5 sole-phi fp diamond e2e smoke
   (bd vyqi): the volatile-single-accumulator idiom END-TO-END — the distilled
   openlibm "***CAUTION***" shape (e_log10l.c `z`) whose exposure by the zco4
   promotion motivated the fp-merge-under-tainted-control investigation. The
   only test layer that LINKS, re-proving the kjd1 controlled-copy symbols
   resolve for the PredMux-flattened diamond (no new runtime ABI — W5 mints
   nothing; Rule 2/16).

   SOURCE INTENT:
       volatile double z;            — the anti-reassociation guard. volatile
         stores are un-speculatable, so clang -O1 CANNOT if-convert this
         diamond itself: it survives to the pass as a real branch with a
         volatile store on EACH arm — exactly the shape class that reaches
         cq-lowering in the wild (a non-volatile twin would arrive as a plain
         select and never exercise W5).
       if (q < 0.5) z = q - 0.5; else z = q * 2.0;
       measure z

   PIPELINE UNDER TEST: promoteVolatileScalarLocals clears the volatile and
   PromoteMemToReg mints the SOLE 2-incoming fp merge phi under the tainted
   fcmp — pre-W5 this loud-declined (the zco4 Inc-1 finding); W5 claims it,
   PredMux flattens the diamond to a tainted fp select, and the kjd1 merge
   lowers it: flag mint (fcmp_olt _hl) → |0⟩ out rail → controlled copy of
   each arm value, the ¬flag one cqrt_x-bracketed → fcmp _inv strip → ONE
   cqrt_free (the flag). Both arm chains and the out rail stay allocated
   (leaked deliberately — the copy marks the DAG NotClosed; freeing an
   entangled source is a hidden measurement, Rules 6/8).

   WHY DETERMINISTIC: trace-only runtime, straight-line post-flatten stream,
   cqrt_measure_f64 returns 0. Golden captured from real linked output
   (templates BEFORE runtime — load-bearing link order) and verified line by
   line analytically. */
double slice(void) {
    volatile double z;
    double q = 0.3;
    cq_theta(&q, 0.5);                 /* taint q -> f64 handle (Ry)          */
    if (q < 0.5) z = q - 0.5;          /* one arm writes z                    */
    else         z = q * 2.0;          /* the other arm writes z              */
    return cq_measure(z);              /* reads the copied-out merge          */
}
int main(void) { (void) slice(); return 0; }
