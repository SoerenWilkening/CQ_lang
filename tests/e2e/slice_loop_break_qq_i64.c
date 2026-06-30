/* slice_loop_break_qq_i64.c — Phase 7.4 (epic y05j) coverage smoke
   (test_C_libtooling-rxx8). The i64-RAIL Q==Q value-arm `break`: the same bare-QQ
   break shape as slice_loop_break_qq.c but with a 64-bit rail/comparand, so the
   index-gated capture + whole-loop reverse-play mint the i64 capture/copy/compare
   symbols rather than the i32 ones:

       long long p = cq_theta(pseed, 0.5);   // 64-bit loop-invariant qubit
       long long q = cq_theta(seed, 0.25);
       for (int i = 0; i < n; i++) {
           q = q ^ 5;                         // in-place i64 value rail
           if (q == p) break;                 // TAINTED i64 Q==Q break flag
       }
       return cq_measure(q);

   WHY THIS IS THE RIGHT LAYER: a missing i64 capture symbol (cqrt_alloc_i64,
   cqrt_copy_i64[_controlled], cqrt_xorc_i64, cq_template_icmp_eq_i64 + its _unc)
   fails LOUDLY at LINK — invisible to the .ll fixtures (which assert IR text and
   never link). This golden is the only proof those i64 break-path symbols resolve and
   signature-match against the runtime (Rule 2/16). The counter stays i32 (the loop
   induction), so this also exercises the MIXED-width capture (i64 rail + i32 idx). `p`
   is loop-invariant and never freed (left allocated-clean, Rule 6 — the bare-QQ
   rationale of slice_loop_break_qq.c, at i64 width). No new frozen runtime ABI.

   The bound `n` is a runtime 4 for a deterministic trace; ZERO measurements inserted;
   `noinline` keeps the function boundary. */
__attribute__((noinline))
long long run(long long seed, long long pseed, int n) {
    long long p = cq_theta(pseed, 0.5);    /* 64-bit loop-invariant qubit */
    long long q = cq_theta(seed, 0.25);
    for (int i = 0; i < n; i++) {
        q = q ^ 5;                          /* in-place i64 value rail self-update */
        if (q == p)                         /* TAINTED i64 Q==Q break flag */
            break;
    }
    return cq_measure(q);
}
int main(void) { (void) run(3, 7, 4); return 0; }
