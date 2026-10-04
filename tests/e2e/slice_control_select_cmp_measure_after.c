/* slice_control_select_cmp_measure_after.c — Track A.1 (bd
   test_C_libtooling-r10v / -r903 item (b)): the ACCEPT that makes the new
   compare-leaf rung (ii) a DISCRIMINATOR and not a blanket refusal. The COMPARE
   twin of `slice_control_select_bool_measure_after`'s shape.

       int q = cq_theta(0, 0.5);
       int a = (q == 1) ? 2 : 5;      // the 4.4 copy merge reads a COHERENT q
       int m = cq_measure(q);         // the measurement owns it from here on
       return cq_measure(a) + m;      // both results observed (else -O1 DCEs the merge)

   `classifySelectRegion` now asks every COMPARE leaf the question it has asked
   every RAIL leaf since Increment 1b-B.1: is the condition register measured
   before the control route? The read point is the SELECT — `SelectMergeEmit`
   emits its whole stream immediately before it — so a same-block measurement
   AFTER the select is the ordinary downstream case and must keep lowering. Move
   the measure one line up and the program is bd `r903` item (b) at the select:
   a flag minted from a collapsed register, which ACCEPTED on `main` 0c7380c
   (lit: `control_swap_reject_select_cmp_measured_before.ll`).

   THE TRACE IS THE ASSERTION: the `cq_template_icmp_eq_i32_hl` mint PRECEDES the
   `cqrt_measure_i32`, and nothing else in the stream moves. STRICT stage 2b. */
#include "CQ.h"

int slice(void) {
    int q = 0; cq_theta(&q, 0.5);
    int a = (q == 1) ? 2 : 5;
    int m = cq_measure(q);
    return cq_measure(a) + m;
}

int main(void) {
    (void) slice();
    return 0;
}
