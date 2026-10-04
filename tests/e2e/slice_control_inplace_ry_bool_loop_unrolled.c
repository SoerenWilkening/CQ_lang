/* slice_control_inplace_ry_bool_loop_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_inplace_ry_bool_loop.c at CQ_K = 2 (no loop at all).

   It is the ORACLE for the rolled form and it is NOT itself new capability: the
   flat bare-`_Bool` controlled-Ry arm shipped with l4x4.b (`e96f89c`) and
   compiles on the frozen 2026-09-14 ORACLE unchanged. That is what retires the
   l4x4.b carve-out's first stated reason ("there is nothing for a rolled trace
   to be byte-identical TO except itself"): the missing twin was the COMPARE
   twin, and the in-loop witness discipline in this tree has never been
   rolled-versus-compare. */

int slice(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int r = 7; cq_theta(&r, 0.25);
    if (b) cq_theta(&r, 0.2);
    if (b) cq_theta(&r, 0.2);
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
