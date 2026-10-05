/* slice_control_inplace_ry.c — control-in-place ROTATION arm e2e smoke (bd
   test_C_libtooling-drbq Inc 1). The only test layer that LINKS, so it proves
   the new frozen-designate symbol `cqrt_ry_i32_controlled` resolves and
   signature-matches against the runtime (Rule 2, Rule 16).

   SOURCE INTENT (PRD §4 shape (a) — ONE tainted-operand cq_theta per arm, on a
   register whose physical wire is disjoint from every condition wire):
       q, r : two INDEPENDENT tainted handles (two cq_theta sources, two rails)
       if (q == 5) cq_theta(&r, 0.9);     // a controlled Ry on r
       measure q; measure r

   WHY THIS IS NOT A SWAP ROUTE (retired since 3qlq), the point of the increment.
   The route's premise was that the arm gate is a no-op on the INACTIVE |0> rail:
   true for Rz = diag(1, e^{i.theta}), FALSE for Ry(t)|0> = cos|0> + sin|1>,
   which hands that rail back DIRTY and ENTANGLED with the flag (Rules 6/8).
   Cleaning it would need a controlled Ry-dagger — method-A, dropped 2026-06-09
   precisely because a gate you would emit to clean a rail is a gate you could
   have controlled in place from the start. So the arm's theta is HOISTED to the
   pred and lowered as `cqrt_ry_i32_controlled(flag, r, 0.9)`: no alloc, no
   cswap, no work rail, no reverse-play.

   WHY THE FLAG STRIP IS STILL VALID: `icmp_eq_i32_hl_unc` recomputes `q == 5`
   and XORs it back onto the flag, which needs q's COMPUTATIONAL BASIS to be what
   the mint read. The only register this stream relabels is r, and r's rail is
   disjoint from q's (two separate cq_theta sources), so q == q0 at the strip and
   the flag returns to |0> before `cqrt_free` (PRD §3).

   The runtime is trace-only and the diamond is flattened to straight-line code,
   so every emitted gate fires unconditionally and the trace is deterministic
   regardless of q's value. cq_theta / cq_measure resolve from CQ.h, force-
   included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);             /* taint q -> handle (alloc i32(3), ry_i32) */
    cq_theta(&r, 0.25);            /* taint r -> a SECOND, disjoint rail       */
    if (q == 5) {                  /* tainted condition -> flag mint at the icmp */
        cq_theta(&r, 0.9);         /* the arm Ry — CONTROLLED and IN PLACE on r  */
    }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
