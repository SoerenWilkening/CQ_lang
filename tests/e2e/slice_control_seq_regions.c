/* 3qlq Inc 1: migrated to register-free cq_phi -- both regions' `q = cq_phi(q, th)` -> `cq_phi(th)`.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_seq_regions.c — bd hcrg e2e smoke: TWO SEQUENTIAL
   tainted-condition phase regions in one function, the only test layer that
   LINKS (Rule 2, Rule 16).

   SOURCE INTENT:
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q > 5) { cq_phi(0.25); }      // region 1
       if (q > 3) { cq_phi(0.75); }      // region 2
       measure q

   After clang -O1 region 2's conditional branch lives INSIDE region 1's merge
   block — region 2's `Pred` IS region 1's `MergeBB`. That pair used to decline
   (`nested control flow under quantum control`) because flattening region 1
   splices + ERASES that block, dangling region 2's cached pointer to it: a
   use-after-free, SIGSEGV on valid input (§8 adversarial review, 2026-06-10).

   Nothing about that was semantic — it was a teardown ORDER bug. The emitter now
   orders emission so no region is emitted after another has erased a block it
   names, and declines loudly on any alias ordering cannot resolve.

   WHAT THIS GOLDEN IS FOR, and why it is not redundant with the lit fixtures:
   the emitters run in REVERSE order here (region 2's emitter runs FIRST, while
   all of its blocks are still live), and the claim that the emitted GATE STREAM
   is nevertheless in SOURCE order rests on each emitter inserting positionally
   into its own pred block. The trace below is the byte-level proof of that
   claim: the `0x1p-2` Rz must precede the `0x1.8p-1` Rz, and each region's flag
   must be minted, used, stripped and freed before the next region's is minted.
   A regression that emitted in plan order would still verify clean, still pair
   every free, and still pass every negative fixture — only this ordering would
   catch it.

   The runtime is trace-only and both diamonds are flattened to straight-line
   code, so every emitted gate fires unconditionally and the trace is
   deterministic regardless of q. */
int slice(void) {
    int q = 7;
    cq_theta(&q, 0.5);             /* alloc i32(7) + ry_i32                  */
    if (q > 5) {                   /* region 1 — swap-routed phase arm       */
        cq_phi(0.25);
    }
    if (q > 3) {                   /* region 2 — its Pred is region 1's merge */
        cq_phi(0.75);
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
