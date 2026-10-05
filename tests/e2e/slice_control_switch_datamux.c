/* slice_control_switch_datamux.c — Phase 4.5 e2e smoke (WI-6,
   test_C_libtooling-bkpz.6): the RSSA tainted-switch constant DATA-MUX (preload +
   XOR-delta controlled copy), the only test layer that LINKS and so the ONLY
   proof that the data-mux switch emitter's symbol set (the eq-flag template +
   its `_unc` strip, the XOR-delta cqrt_alloc, cqrt_copy_i32_controlled) resolves and
   signature-matches against libcq_runtime (Rule 2, Rule 16).

   SOURCE INTENT (all-ConstantInt merge — a compile-time multiplexer, the §4C
   ACCEPT shape; control_swap_switch_datamux.ll is the pinned IR contract):
       q : tainted quantum SCRUTINEE handle (the condition register)
       int r = 3;                                  // the default value v_d
       switch (q) { case 0: r=7; case 5: r=9; case 17: r=11; }
       measure r

   TWO -O1-SURVIVAL TRICKS — a const data-mux is exactly what clang -O1 folds, so
   the C is shaped to keep a REAL `switch` (the data-mux fixture is hand-written
   for this very reason):
     (1) NON-CONTIGUOUS case values (0, 5, 17). The natural contiguous form
         (case 0/1/2) folds to a `select` chain (2-3 distinct results) — exercising
         the 4.4 select path, NOT this switch path; sparse values defeat both the
         select-fold and the lookup-table-fold (a table over [0..17] is not
         beneficial), so the switch survives.
     (2) PRE-INITIALIZE r = v_d (= 3) and OMIT the explicit `default:` body. With
         an explicit `default: r=3`, -O1 routes case 0 DIRECTLY to the merge
         (its empty block collapses onto the entry edge), so the entry-incoming
         carries case 0's value (7) while v_d (3) sits in a separate block — an
         irregular shape the classifier declines ("control flow"). Pre-init makes
         the entry straight-through edge carry v_d itself, so every case keeps its
         own block and the default is the PRELOAD (the §4C model exactly).

   The lowering PRELOADS out = cqrt_alloc_i32(v_d=3), then per content case mints
   the eq-flag f_i=(q==c_i), allocs the COMPILE-TIME XOR-delta d_i = v_i ^ v_d
   (7^3=4, 9^3=10, 11^3=8), and fires cqrt_copy_i32_controlled(f_i, d_i, out) —
   out ^= d_i iff f_i. Distinct literals => mutually exclusive flags => at most one
   copy fires: matched case k gives out = v_d ^ (v_k ^ v_d) = v_k; no match leaves
   out = v_d. Then each flag is stripped with icmp_eq_i32_hl_unc(f_i, q, c_i)
   (`_inv` when written; bd 8txa; the copies write out, never q) and freed.
   RAUW merge->out — the measure reads the muxed answer.

   EXACTLY THREE frees (the N=3 flags only). out (the result), q, and every XOR-
   delta scratch are NEVER freed — a benign classical leak (Rule 6); a free here
   would be a hidden measurement. NO route cswap, NO ¬-bracket cqrt_x (distinct
   literals are disjoint — the default is the PRELOAD, not a synthesized ¬OR flag),
   NO reverse-play, NO controlled rotation, no surviving `phi i32`. The runtime is
   trace-only, so every emitted gate fires unconditionally; cqrt_measure returns 0.
   The golden pins the trace captured from REAL linked output (templates BEFORE
   runtime — load-bearing link order). cq_theta/cq_measure resolve from CQ.h. */
int slice(void) {
    int q = 3, r = 3;              /* r preset to v_d (the default value)         */
    cq_theta(&q, 0.5);             /* taint q -> scrutinee handle                */
    switch (q) {                   /* tainted switch -> preload + XOR-delta mux   */
        case 0:  r = 7;  break;    /* delta 7^3=4                                 */
        case 5:  r = 9;  break;    /* delta 9^3=10  (non-contiguous: defeats fold)*/
        case 17: r = 11; break;    /* delta 11^3=8                                */
    }
    return cq_measure(r);          /* reads the muxed answer (out)               */
}
int main(void) { (void) slice(); return 0; }
