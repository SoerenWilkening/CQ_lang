/* slice_control_inplace_ry_loop_iterlocal_derived.c — bd
   `test_C_libtooling-wx8g`, R7-loop CLAUSE (c) with a DERIVED condition, which
   is the pair that makes clause (c3) a measurable fence rather than a comment.

       for (k < K) { int r = cq_theta(7, .25);
                     if ((q >> k) & 1) cq_theta(&r, .2);
                     s += cq_measure(r); }

   Unlike the `_Bool` slices, this body mints TEMPLATE rails for the condition
   (`cq_template_lshr_i32_hl`, `cq_template_and_i32_hl`) whose `_unc` + free are
   the WHOLE-DAG SPINE's to place, not the emitter's — so the golden below is
   the one in this family that can show a per-trip discharge at all, and its
   twin is the one that can show the discharge going MISSING. `free_pairing_check.py`
   is structurally blind to a leaked template rail (it counts `cqrt_alloc` sites),
   so the byte-diff is the only instrument here.

   MEASURED: the same program with the per-trip register read AFTER the loop
   instead of inside it emits 19 trace lines rolled against 27 hand-unrolled —
   two entangled which-path records of `q`'s bits leaked per activation, `opt`
   exit 0 and stage-2b clean on both. Clause (c3) is what refuses it; the pinned
   decline is ir-pass/test/control_inplace_ry_reject_inloop_iterlocal_escape.ll.

   Twin: slice_control_inplace_ry_loop_iterlocal_derived_unrolled.expected.log. */

#ifndef CQ_K
#define CQ_K 2
#endif

int slice(void) {
    int q = 5; cq_theta(&q, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = 7; cq_theta(&r, 0.25);
        if ((q >> k) & 1) cq_theta(&r, 0.2);
        s += cq_measure(r);
    }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
