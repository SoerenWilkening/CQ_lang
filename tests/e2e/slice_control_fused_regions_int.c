/* slice_control_fused_regions_int.c — bd test_C_libtooling-b6ap: THE MULTI-PHI
   MERGE PEEL, and this is the OWNER'S OWN `main()`
   (`example/grover/grover_oracle_uncompute.c` as it stood 2026-09-11) with
   `bool b0` / `bool b1` written as `int` — the one-token change that makes the
   peel ALONE sufficient (SCOPE_b6ap.md §16).

   SOURCE INTENT, as typed:
       int a = 5; int b0 = 0; int b1 = 0;
       if (a >= 3) cq_theta(&b0, 0.5);   // classical guard: always taken
       if (b0 == 1) a -= 3;                  // a becomes 2 or 5 with b0
       if (a >= 3) cq_theta(&b1, 0.5);   // a state prep, guarded by a again
       return cq_measure(b0) + cq_measure(b1) + cq_measure(a);

   WHAT clang -O1 HANDS THE PASS (Rule 9 — the trace will not match what you
   typed). `a` is the constant 5, so `a >= 3` folds; but the THIRD `if` reads the
   POST-mux `a`, and -O1 proves `a >= 3` there is exactly `b0 != 1`. The second
   and third source regions therefore FUSE INTO ONE DIAMOND whose merge block
   holds TWO phis:
       %amux = phi i32 [ 5, %arm ], [ 2, %entry ]    the `a` DATA MUX
       %b1   = phi i32 [ %t1, %arm ], [ 0, %entry ]  the `b1` STATE PREP
   `ControlRegion::Merge` is a single `PHINode *`, so `soleMergePhi` returns null
   and, on `main` 0c7380c, the whole program declines
       cq controlled lowering: control flow under quantum control
   anchored at that `br`. NOTHING SEMANTIC IS WRONG WITH IT — the decline is the
   emitter's bookkeeping, which is exactly the case CLAUDE.md's hcrg bullet says
   to re-examine.

   `peelIndependentMergePhis` replaces `%amux` — every one of whose incomings is
   available at the pred — with `select i1 <clone of the region's compare>, 2, 5`
   at the phi's own position, leaving the ONE phi the region needs. Nothing else
   moves: the arm, the CFG and `%b1` are untouched, and the peel emits no gate.

   EXPECTED TRACE (measured, the golden — 22 lines). Two INDEPENDENT flag
   mint/strip/free triples on the same wire, which is the shipped sequential-
   regions shape (bd hcrg):
       alloc_i32(0) -> h0 ; ry_i32(h0, 0.5)                   the `b0` register
       icmp_eq_i32_hl(h0, 1) -> h1                            REGION: flag mint
       x(h1) ; alloc_i32(0) -> h2 ; ry_i32_controlled(h1, h2, 0.5) ; x(h1)
                                                  the drbq Inc-4 state prep, ¬flag
       icmp_eq_i32_hl_unc(h1, h0, 1) ; free(h1)               strip, proven-|0> free
       icmp_eq_i32_hl(h0, 1) -> h3                            SELECT: its OWN mint
       alloc_i32(0) -> h4                                     the |0> out rail
       alloc_i32(2) -> h5 ; copy_i32_controlled(h3, h5, h4)   fires on b0 == 1
       x(h3) ; alloc_i32(5) -> h6 ; copy_i32_controlled(h3, h6, h4) ; x(h3)
       icmp_eq_i32_hl_unc(h3, h0, 1) ; free(h3)
       measure_i32(h0) ; measure_i32(h2) ; measure_i32(h4)

   WHY THE SELECT MINTS ITS OWN FLAG instead of sharing the region's (SCOPE §6,
   MEASURED): a peeled select that reuses the region's compare VALUE declines
   `condition data use neither escaped nor measured` — `classifyArms` sees a
   non-`BranchInst` user of the condition and `condDataUseDisposition` does not
   recognize a `SelectInst`, so it ends at its `Unowned` catch-all. The clone
   costs one transient flag rail, minted and freed, and changes no fence: the
   wire guards are asked of the clone exactly as of the original.

   EXACTLY TWO frees (the two flags). The register, the prepped rail `h2`, the
   out rail `h4` and both materialized sources are LEFT ALLOCATED — each is
   entangled through the controlled copy or the controlled Ry, and freeing one
   would be a hidden measurement (Rules 6/8). STRICT stage 2b.

   THE OWNER'S FILE AS WRITTEN (`bool b0`, `bool b1`) still declines after this
   increment, one wall further in: `bare i1 register condition` at the state-prep
   arm on a bare rail — bd `l4x4` (Inc 1b-C). Measured on this binary; the peel
   itself handles the bool spelling fine (P7 clause (b) admits a rail leaf).
   The `bool` half that DOES compile today is
   `slice_control_fused_regions_phase_bool.c` beside this file. */
#include "CQ.h"

int main(void) {
    int a = 5;
    int b0 = 0;
    int b1 = 0;

    if (a >= 3) {
        cq_theta(&b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    if (a >= 3) {
        cq_theta(&b1, 0.5);
    }

    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
