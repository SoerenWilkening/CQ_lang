/* slice_control_value_diamond_twin.c — the PRE-HOISTED SELECT TWIN of
   slice_control_value_diamond.c (bd test_C_libtooling-3qlq Inc 2,
   retire-swap-route-PRD §7.4). Its committed golden must be BYTE-IDENTICAL to
   the subject's; `e2e-value-diamond-twin-identical` is that `cmp`.

   WHY THIS PROGRAM AND NOT `p = (q > 5) ? R(p) : p;`. The PRD proposed the `?:`
   spelling as the twin. MEASURED 2026-09-05 on the pre-3qlq oracle: `clang -O1`
   compiles `p = (q>5) ? R(p) : p` and `if (q>5) p = R(p)` to IR that differs
   only in a `; preds =` COMMENT — SimplifyCFG's speculation cost threshold, not
   the source spelling, decides select-vs-diamond, so a six-op `?:` arrives as a
   DIAMOND too and the "twin" would be the subject program itself. The witness
   that actually exists is this one: compute the chain UNCONDITIONALLY into `t`,
   then select. `-O1` hands that to the pass as a straight-line chain plus
   `select i1 %c, i32 %t, i32 %p` — which is EXACTLY the shape Inc 2's
   `emitValueRegion` rewrites the diamond into, and which lowers through the
   Rule-13-cleared 4.4 `SelectMergeEmit`. So the twin is the MANUAL spelling of
   the increment's own transformation (the drbq Inc-2b by-difference-twin
   precedent), and byte identity says the rewrite is that transformation and
   nothing else.

   Same six-op chain, same angles, same measure as the subject. STRICT stage 2b. */
static inline int R(int p) {
    p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2;
    return p;
}
int slice(void) {
    int q = 3;
    int p = 7;
    cq_theta(&q, 0.5);
    cq_theta(&p, 0.25);
    int t = R(p);                  /* the chain, hoisted BY HAND into the pred  */
    p = (q > 5) ? t : p;           /* -> select i1 %c, i32 %t, i32 %p            */
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
