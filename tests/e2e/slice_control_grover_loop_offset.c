/* slice_control_grover_loop_offset.c — bd test_C_libtooling-8h7d.5. A rolled loop
   whose REGISTER IS MUTATED IN PLACE, on both sides of the back edge.

   THIS SLICE EXISTS BECAUSE ITS ABSENCE HID A SILENT MISCOMPILE. The round-2 rail
   collapse (`collapseFlattenedLoopRails`) RAUWs the loop-carried header phi to its
   root mint; when the rail chain contains a value self-update (`q += off`, issue
   dtzb) that op must ALSO be marked into `taint.InPlaceRailOps`, exactly as round
   1 marks it, or `lowerOps` emits it OUT of place into a fresh rail nobody reads
   and every in-loop use resolves to the PRE-offset handle. The circuit then
   computes on `q` where the source says `q + off`.

   Measured 2026-08-29 while re-measuring example/grover/grover_loop_frontier.c:
   `opt` exit 0, `opt -verify` clean, STRICT stage-2b free-pairing CLEAN, and the
   only outward sign was one M-A warning about a live derived record. The golden
   below is what the fix produces; without the marking the third line of the trace
   reads `cq_template_add_i32_hl(h0, 3) -> h1` — a fresh rail — instead of
   `cqrt_addc_i32(h0, 3)`, and h1 is never used again.

   `cq_off` is `volatile` so `clang -O1` cannot fold or cancel the offsets (Rule
   9): the pair survives canonicalization and reaches the pass as real reversible
   arithmetic on the quantum register, and the immediate is a RUNTIME value, which
   is why the trace prints `cqrt_addc_i32(h0, 3)` rather than a literal-folded form.

   Note the shape: the PRE-LOOP `q += off` lands on the header phi's EXTERNAL
   incoming chain and the in-body one lands on its LATCH incoming chain — the
   collapse peels through both, so the fixture covers both sides.

   Its hand-unrolled twin is slice_control_grover_loop_offset_unrolled.c and the
   goldens are `cmp`'d in ctest. STRICT stage 2b. */

#define CQ_PI 3.14159265358979323846

volatile int cq_off = 3;

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);
    q += cq_off;                             /* on the PRE-HEADER chain */

    for (int i = 0; i < 2; ++i) {
        if (q == 5) {
            q = cq_phi(q, CQ_PI);
        }
        q = cq_theta(q, -0.5);
        q += cq_off;                         /* on the LATCH chain */
        q = cq_theta(q, 0.5);
    }

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
