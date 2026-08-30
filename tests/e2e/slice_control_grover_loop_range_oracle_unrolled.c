/* slice_control_grover_loop_range_oracle_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_range_oracle.c (bd test_C_libtooling-8h7d.5, Rule-13
   round 4, finding OD-A).

   Same body, twice, no loop. Its golden is the reference the rolled form is
   byte-diffed against (ctest entry e2e-grover-loop-range-oracle-twin-identical).

   THIS SIDE COMPILED AT HEAD while the rolled form declined, which is what
   identified the decline as a compiler over-decline rather than a property of the
   program: `clang -O1` emits the SAME `add %a, -6; icmp ult %t, 14`
   canonicalization here, and outside a loop nothing mistakes that temp for the
   loop-carried rail because there is no loop-carried rail to mistake it for. */

#define CQ_RANGE_ORACLE_ITER                              \
    if (a > 5 && a < 20) {                                \
        a = cq_phi(a, 3.14159265358979323846);            \
    }                                                     \
    a = cq_theta(a, -0.5);

int slice(void) {
    int a = 0;

    a = cq_theta(a, 0.5);

    CQ_RANGE_ORACLE_ITER
    CQ_RANGE_ORACLE_ITER

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
