/* slice_control_value_mixedops_twin.c — the PRE-HOISTED SELECT TWIN of
   slice_control_value_mixedops.c (bd test_C_libtooling-3qlq Inc 2). Byte-identical
   golden required; `e2e-value-mixedops-twin-identical` is that `cmp`. See
   slice_control_value_diamond_twin.c for why a `?:` spelling is NOT a twin. */
static inline int R(int p) {
    p = p - 3; p = p & 1023; p = p | 64; p = p << 2; p = p ^ 5; p = p * 3;
    return p;
}
int slice(void) {
    int q = 3;
    int p = 7;
    q = cq_theta(q, 0.5);
    p = cq_theta(p, 0.25);
    int t = R(p);
    p = (q > 5) ? t : p;
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
