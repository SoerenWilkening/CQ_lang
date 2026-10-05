/* slice_control_inplace_ry_stateprep.c — the FLAGSHIP e2e for CONTROLLED STATE
   PREP (control-in-place-PRD §14, bd test_C_libtooling-drbq Inc 4).

   SHAPE: a flat diamond whose single content arm is one `cq_theta` with a
   CLASSICAL CONSTANT arg-0. The theta does not rotate a live register — it MINTS
   one. `SwapRouteEmit` hoists it to the pred; `lowerRotations` takes its
   `!Chained` arm (`cqrt_alloc_i32(0)`) AT THE HOISTED POSITION and then mints
   `cqrt_ry_i32_controlled(f, h, θ)` instead of the unconditional gate.

   WHY IT IS THE MECHANISM AND NOT A PEEPHOLE: the retired swap route could not
   carry an Ry at all. `Ry(θ)|0> != |0>`, so the inactive work rail would be handed
   back DIRTY and ENTANGLED with the flag (Rules 6/8, PRD §2).

   WHAT THIS GOLDEN PROVES, AND WHAT IT DOES NOT — say both, because the
   comfortable reading is wrong. NO trace can witness "the fresh rail holds
   |SEED> on the f=0 branch": the runtime prints symbols and handles, and no ABI
   label answers a STATE question. What the golden pins is the STRUCTURE — one
   alloc carrying the seed, one CONTROLLED gate naming it, the flag minted from
   the same compare and stripped by the same `_unc`, exactly ONE `cqrt_free` (the
   flag's), and no route, no work rail, no reverse-play. The VALUE claim rests on
   two other things, named here rather than implied: (a) `cqrt_alloc_i32(0)` is
   the SAME call the uncontrolled `int r = 0; cq_theta(&r, θ)` mints today, pinned by the
   existing runtime goldens; and (b) F1, the seed-identity fence, which is what
   makes |SEED> the right thing for the f=0 branch to hold.

   ⚠ AND STAGE 2b WITNESSES NEITHER. `free_pairing_check.py` classifies
   `cqrt_alloc_<W>` BY SYMBOL NAME ONLY and never reads the seed argument at any
   site, so a WRONG SEED IS INVISIBLE TO IT; and the frozen rail lands in its
   "left allocated" census with no finding. Quoting a green 2b as evidence for
   this increment would be false. It runs STRICT here anyway, for what it does
   cover: no use-after-free of the flag, no dirty free.

   THE FREEZE: the prepped rail is never reverse-played and never freed
   (`ChainWalk::railCarriesControlledRotation`, asked structurally of the emitted
   gate's own arg-1 use). A controlled gate's adjoint needs its CONTROL, and the
   flag is stripped and freed three lines earlier — emitting one would be a
   use-after-free followed by a dirty free of a condition-entangled rail (the
   measured Inc-1 defect). The rail is LEFT ALLOCATED: Rule 6's sanctioned
   fallback in the qubits-not-scarce regime, O(1) per region.

   THE TWIN: `slice_control_inplace_ry_stateprep_twin.c` is the manual CHAINED
   spelling `int r = 0; cq_theta(&r, 0.0); if (…) cq_theta(&r, .9);`, which the
   PRE-INC-4 binary already lowers. This golden is its REDUCTION under two
   rewrites that are physical identities and are NOT the transformation under
   test — (i) delete `cqrt_ry_i32(h, 0x0p+0)` because Ry(0) = I, (ii) move the
   fresh-rail alloc to just before the first controlled gate naming it, because a
   fresh-rail alloc commutes with every gate that does not name its handle — plus
   a renumbering. Both goldens are committed so the reduction can be re-derived
   BY HAND rather than from a script nobody re-runs. */
int slice(void) {
    int q = 3; cq_theta(&q, 0.3);  /* the condition register                    */
    int r = 0;                     /* the straight-through value — F1's subject */
    if (q == 5) {                  /* tainted condition -> flag mint at the icmp */
        r = 0; cq_theta(&r, 0.9);  /* CLASSICAL seed: alloc + controlled Ry     */
    }
    return (int) cq_measure(r) + (int) cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
