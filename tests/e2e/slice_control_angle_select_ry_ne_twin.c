/* slice_control_angle_select_ry_ne_twin.c — the MANUAL by-difference twin of
   `slice_control_angle_select_ry_ne.c` (bd test_C_libtooling-drbq Increment 2b).

       cq_theta(&r, 0.9);                   // the FALSE-arm angle
       if (q == 5) cq_theta(&r, 0.3 - 0.9); // the controlled difference

   Note the polarity, which is the whole reason this twin is written `q == 5`
   while its subject is written `q != 5`: the compiler's canonicalization already
   turned the source's `!=` into an `icmp eq` with swapped select arms, so the
   by-difference form the emitter produces is the `==` one with a NEGATIVE
   difference. Writing the twin as `q != 5` would produce a `cqrt_x`-bracketed
   diamond and a DIFFERENT (also correct) stream, which would make the
   comparison meaningless.

   ⚠ HISTORY SINCE bd dm7f.6: the subject emits the X-bracket stream of the
   if/else (`slice_control_angle_select_ry_ne.c`), which is now its byte twin
   (`e2e-angle-select-ry-ne-twin-identical`); this file still pins the
   by-difference in-place diamond on its own. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    cq_theta(&r, 0.9);
    if (q == 5) cq_theta(&r, 0.3 - 0.9);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
