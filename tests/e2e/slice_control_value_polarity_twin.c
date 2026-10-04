/* slice_control_value_polarity_twin.c — the PRE-HOISTED SELECT TWIN of
   slice_control_value_polarity.c (bd test_C_libtooling-3qlq Inc 2, Rule-13
   round-1 review finding F-V1-7). Its committed golden must be BYTE-IDENTICAL
   to the subject's; `e2e-value-polarity-twin-identical` is that `cmp`.

   Same construction as slice_control_value_diamond_twin.c — compute the chain
   unconditionally into `t`, then select — but with the NEGATED condition, so
   `-O1` hands the pass `select i1 (icmp eq %q, 5), i32 %p, i32 %t`: the arm
   value in the FALSE slot, spelled by the source rather than derived by
   `emitValueRegion` from `ArmNegated`. If the emitter ever swapped its two
   operands for a negated diamond, this gate goes red and nothing else in the
   tree would. STRICT stage 2b. */
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
    p = (q != 5) ? t : p;          /* -> select i1 %c, i32 %p, i32 %t            */
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
