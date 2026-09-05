/* slice_control_value_derived.c — e2e smoke for a value diamond over a DERIVED
   base (a pre-region `cq_phi` on the value register; the 9hh discipline) under
   the Inc-2 controlled-copy merge.

   ⚠ NO TWIN AND NO `cmp` GATE, deliberately — and the earlier version of this
   header said otherwise, which is the correction (bd test_C_libtooling-3qlq
   Inc 2, Rule-13 round-1 review finding F-V2-2: it named
   `e2e-value-derived-twin-identical` and slice_control_value_derived_twin.c,
   neither of which exists; `grep -rn` returned only those two lines of this
   header). MEASURED, by writing the missing twin
   (`int t = R(p); p = (q>5) ? t : p;` after the same pre-region `cq_phi`): it
   DECLINES `cq controlled lowering: control flow under quantum control` on the
   pre-3qlq oracle 52d7764 AND on the Inc-2 binary. `SelectClassify`
   conservatively refuses a coherent Rz-lineage select OPERAND, while the
   `br`-value classifier deliberately ACCEPTS a derived base. Inc 2 reuses the
   select EMITTER, not the select CLASSIFIER, so the two dispositions differ BY
   DESIGN and a byte-identity gate here would assert something false (the drbq
   Inc-4 "no `cmp` twin gate, deliberately" precedent). tests/e2e/CMakeLists.txt
   already carried that rationale and was right; the two records now agree. The
   third twin pair is `mixedops`.

   `p = cq_phi(p, 0.9)` before the region makes the merged slot a DIAGONAL ALIAS
   of `p`'s wire — neither is in the condition's provenance, so the region is
   accept-class (the positive contrast for the alias-closure decline). Rotation
   lowering RAUWs both names to the SAME i32 handle, so the emitted stream is the
   plain diamond's plus one unconditional `cqrt_rz_i32` strictly before the
   hoisted chain. What this slice exercises is the derived-base derivation of the
   merge's straight-through operand: get that wrong and the second controlled
   copy names the wrong register. It is also the ONE accept in the value family
   that reaches `emitSelectRegion` with an input its own classifier would refuse
   — the round-1 REVIEWER FLAG, which wants a lens of its own. STRICT
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
