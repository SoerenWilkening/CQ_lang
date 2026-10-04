/* slice_loop_break_qq.c — Phase 7.4 (epic y05j) coverage lock
   (test_C_libtooling-x1t1). A classically-bounded, data-mutating loop with a
   SINGLE tainted value-arm `break` whose condition compares the rail against a
   SECOND loop-invariant QUBIT `p` (Q==Q) — vs slice_loop_break.c, whose break
   compares the rail against a CONSTANT (`(q&1)==0`):

       int p = pseed; cq_theta(&p, 0.5);  // a second, loop-invariant qubit
       int q = seed; cq_theta(&q, 0.25);
       for (int i = 0; i < n; i++) {
           q = q ^ 5;                  // in-place value rail
           if (q == p) break;          // TAINTED Q==Q break flag (rail vs p)
       }
       return cq_measure(q);

   The Q==Q break-cond lowers to the BARE two-handle compare template
   `cq_template_icmp_eq_i32(h_rail, h_p)` and its void adjoint
   `cq_template_icmp_eq_i32_unc(out, h_rail, h_p)` — a DISTINCT code path from
   the `_hl` (handle+literal) form the other break slices exercise. Everything
   else is the §2.2/§2.3 break machinery (slice_loop_break.c): the rail collapses
   to ONE in-place handle (`cqrt_xorc_i32(h, 5)`), the terminator is stripped to
   the classical bound (full trip count, the break is virtual, PRD §2.9), and the
   break is realized by the index-gated copy-not-move CAPTURE + whole-loop
   REVERSE-PLAY. `p` is loop-INVARIANT and never mutated, so the backward
   reverse-play clone of the break-cond reads the SAME `h_p` handle — `fire'`
   recomputed in the reverse-play matches `fire` forward on every amplitude
   branch.

   WHY `p` IS LEFT ALLOCATED, NEVER FREED (Rule 6/8): `p` is NOT disentangled at
   loop end. The break fires when `rail == p`, so the captured/escaping answer
   EQUALS `p` on every break branch — `out` and `p` are ENTANGLED and `p`'s reduced
   state is MIXED, not a pure `Ry|0>`. `p` is therefore a dirty rail NOT provably
   `|0>`; it is LEFT ALLOCATED (a Rule-6 safe leak in the qubits-not-scarce regime).
   Reverse-playing or freeing `p` would be a HIDDEN MEASUREMENT collapsing the
   answer (Rule 6/8). The whole-DAG spine never frees `p` because the live forward
   QQ compare consumes its handle (`isTerminalHandle` is false) and the handle is
   not control-owned, so `p`'s DAG is never recovered. The trace shows NO
   `cqrt_free` of h0 (p).

   This is the ONLY layer that LINKS the bare-QQ `cq_template_icmp_eq_i32` +
   `cq_template_icmp_eq_i32_unc` for the BREAK reverse-play path (the .ll fixture
   lowering_loop_break_qq.ll asserts IR text and never links; slice_compare_qq.c
   links the QQ compare grid only for the straight-line / whole-DAG-uncompute
   path, not the break clone). Rules 2, 16.

   The bound `n` is a RUNTIME parameter passed a fixed 4 so the trace is
   deterministic. ZERO measurements inserted; `noinline` keeps the function
   boundary. cq_theta/cq_measure resolve from CQ.h. */
__attribute__((noinline))
int run(int seed, int pseed, int n) {
    int p = pseed; cq_theta(&p, 0.5);   /* second, loop-invariant qubit */
    int q = seed; cq_theta(&q, 0.25);
    for (int i = 0; i < n; i++) {
        q = q ^ 5;                      /* in-place value rail self-update */
        if (q == p)                     /* TAINTED Q==Q break flag (rail vs p) */
            break;
    }
    return cq_measure(q);
}
int main(void) { (void) run(3, 7, 4); return 0; }
