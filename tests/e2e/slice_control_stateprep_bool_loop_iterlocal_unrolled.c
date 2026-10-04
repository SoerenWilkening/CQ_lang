/* slice_control_stateprep_bool_loop_iterlocal_unrolled.c — the HAND-UNROLLED
   TWIN of slice_control_stateprep_bool_loop_iterlocal.c at CQ_K = 2.

   ⚠ THE MEASUREMENTS STAY INSIDE THEIR OWN BLOCK, one per unrolled copy, and
   that is not cosmetic: pulling both to the end is a DIFFERENT PROGRAM whose
   trace differs from the rolled one by the position of the first
   `cqrt_measure_i32` (measured 2026-09-14 — the two streams are otherwise the
   same multiset). A twin must be the loop body written out, statement for
   statement. */

int slice(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int s = 0;
    { int r = 7; if (b) { r = 7; cq_theta(&r, 0.2); } s += cq_measure(r); }
    { int r = 7; if (b) { r = 7; cq_theta(&r, 0.2); } s += cq_measure(r); }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
