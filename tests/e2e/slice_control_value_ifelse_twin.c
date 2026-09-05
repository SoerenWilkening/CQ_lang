/* slice_control_value_ifelse_twin.c — the PRE-HOISTED SELECT TWIN of
   slice_control_value_ifelse.c (bd test_C_libtooling-3qlq Inc 2). Its committed
   golden must be BYTE-IDENTICAL to the subject's;
   `e2e-value-ifelse-twin-identical` is that `cmp`. See
   slice_control_value_diamond_twin.c for why a `?:` spelling is NOT a twin
   (measured: `-O1` gives the same diamond for both spellings at this arm size).
   Both chains computed unconditionally, then ONE select. */
static inline int R1(int p) {
    p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2;
    return p;
}
static inline int R2(int p) {
    p = p + 4; p = p * 3; p = p ^ 6; p = p + 2; p = p * 9; p = p ^ 1;
    return p;
}
int slice(void) {
    int q = 3;
    int p = 7;
    q = cq_theta(q, 0.5);
    p = cq_theta(p, 0.25);
    int t1 = R1(p);
    int t2 = R2(p);
    p = (q > 5) ? t1 : t2;
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
