/* slice_control_inplace_ry_cond_register.c — an in-place Ry on the CONDITION's
   own register, flag kept (bd test_C_libtooling-dm7f.4, owner ruling
   2026-10-03, option (a)). The only test layer that LINKS, so it proves the
   kept-flag stream resolves against the runtime, and run_slice.sh's stage 2b
   checks that no free in it is unpaired.

   SOURCE INTENT:
       q, p : two independent tainted registers
       if (q > 5)        cq_theta(&q, 0.9);   // Ry on the register q > 5 reads
       if ((p & 3) == 2) cq_theta(&p, 0.7);   // the same, through a derived chain
       measure q; measure p

   WHY THE FLAG IS NOT STRIPPED. The strip `icmp_..._unc` recomputes the
   predicate on the condition's registers. Here the controlled Ry has just
   relabelled that register, so the recomputation would not return the flag to
   |0> and its free would be a hidden measurement (R5). The flag is therefore
   minted, used as the control, and LEFT ALLOCATED; it holds the pre-Ry
   predicate, which is the which-branch record the source's non-unitary map
   |x> -> (x > 5 ? Ry|x> : |x>) needs. `opt` prints one M-A warning per gate
   (owner ruling lyyf) and exits 0.

   WHAT THE SECOND REGION ADDS. Its condition reads p through an `and` rail.
   That rail's only reader is the flag mint, so the uncompute spine discharges
   it (`and_unc` + `cqrt_free`) BEFORE the controlled Ry, while p still holds
   the basis the `and` read. Only the flag stays.

   The runtime is trace-only and the regions are flattened to straight-line
   code, so the trace is deterministic. cq_theta / cq_measure resolve from CQ.h,
   force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    int p = 6;
    cq_theta(&q, 0.5);
    cq_theta(&p, 0.25);
    if (q > 5) {
        cq_theta(&q, 0.9);         /* controlled Ry on the condition's register */
    }
    if ((p & 3) == 2) {
        cq_theta(&p, 0.7);         /* the same, through a derived condition     */
    }
    return cq_measure(q) + cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
