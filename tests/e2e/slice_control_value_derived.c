/* slice_control_value_derived.c — e2e smoke for a value diamond over a DERIVED
   base (a pre-region `cq_phi` on the value register; the 9hh discipline) under
   the Inc-2 controlled-copy merge. Subject of
   `e2e-value-derived-twin-identical`; its twin is
   slice_control_value_derived_twin.c.

   `p = cq_phi(p, 0.9)` before the region makes the merged slot a DIAGONAL ALIAS
   of `p`'s wire — neither is in the condition's provenance, so the region is
   accept-class (the positive contrast for the alias-closure decline). Rotation
   lowering RAUWs both names to the SAME i32 handle, so the emitted stream is the
   plain diamond's plus one unconditional `cqrt_rz_i32` strictly before the
   hoisted chain. This is the third twin pair and the one that exercises the
   derived-base derivation of the merge's straight-through operand: get that
   wrong and the second controlled copy names the wrong register. STRICT
   stage 2b. */
int slice(void) {
    int q = 3;
    int p = 7;
    q = cq_theta(q, 0.5);
    p = cq_theta(p, 0.25);
    p = cq_phi(p, 0.9);            /* DERIVED base — diagonal alias of p's wire */
    if (q > 5) { p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2; }
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
