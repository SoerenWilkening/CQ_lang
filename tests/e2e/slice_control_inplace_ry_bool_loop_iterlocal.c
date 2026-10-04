/* slice_control_inplace_ry_bool_loop_iterlocal.c — bd `test_C_libtooling-wx8g`,
   R7-loop CLAUSE (c): the ITERATION-LOCAL rotated register.

       for (k < K) { int r = 7; cq_theta(&r, .25);  // a FRESH rail every trip
                     if (b) cq_theta(&r, .2);
                     s += cq_measure(r); }

   `r`'s rail does NOT cross the back edge, so there is no header phi and
   clause (b) can never fire — that is why every such program declined
   `control flow inside a loop body` BY CONSTRUCTION until 2026-09-14. Clause
   (c) proves the complementary thing instead: the mint sits INSIDE the loop, so
   the rolled body allocates K fresh rails exactly as K copies of it would, and
   nothing tainted defined in the loop is read outside it.

   Each per-trip register is MEASURED inside the body, so the user owns it;
   nothing is freed and nothing is left dirty across the back edge.

   Twin: slice_control_inplace_ry_bool_loop_iterlocal_unrolled.expected.log. */

#ifndef CQ_K
#define CQ_K 2
#endif

int slice(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = 7; cq_theta(&r, 0.25);
        if (b) cq_theta(&r, 0.2);
        s += cq_measure(r);
    }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
