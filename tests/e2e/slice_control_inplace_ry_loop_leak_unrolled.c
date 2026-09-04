/* slice_control_inplace_ry_loop_leak_unrolled.c — the hand-unrolled twin of
 * slice_control_inplace_ry_loop_leak.c (bd test_C_libtooling-drbq Increment 3,
 * round-1 lens L3 Q1). Same text, dedented and written out twice.
 *
 * Its job is to show that the O(K) freeze leak the rolled slice measures is the
 * FREEZE's cost and not the ROLL's: this flat form strands the same 2 template
 * rails per repetition, for the same reason, and its trace is BYTE-IDENTICAL
 * (ctest `e2e-inplace-ry-loop-leak-twin-identical`).
 *
 * Unlike the rolled side this program compiles on the PRE-Increment-3 binary
 * too — it is the Increment-1 flat control-in-place lowering, which is the stated
 * oracle for every slice in this family.
 */
#include <stdio.h>

int slice(void) {
    int q = 0; int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    { int s = r * 7; printf("%d\n", s); }
    if (q == 5) { r = cq_theta(r, 0.9); }
    q = cq_phi(q, 0.1);
    { int s = r * 7; printf("%d\n", s); }
    if (q == 5) { r = cq_theta(r, 0.9); }
    q = cq_phi(q, 0.1);
    return cq_measure(q) + cq_measure(r);
}

int main(void) { (void)slice(); return 0; }
