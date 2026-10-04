/* slice_control_phase_onward_perbit_loop_mixed_unrolled.c — the HAND-UNROLLED
   TWIN of `slice_control_phase_onward_perbit_loop_mixed.c` (bd
   test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round, finding F-C1-2(2a)).

   Byte-identity of the two goldens is the witness, checked by
   `e2e-phase-onward-perbit-loop-mixed-twin-identical`. It was 41 lines vs 47 on
   542d588 and on the round-1 C-1 fix; it is 47 = 47 now.

   ⚠ It EXISTS here only because this shape's flat spelling still lowers. The
   sibling shape with a ROUND-1 region in the same body (`r40`, pinned at the lit
   layer by `control_phase_kickback_mixed_onward_r1open_inloop.ll`) has NO twin:
   its hand-unrolled form declines `cq controlled lowering: control flow under
   quantum control` on every binary in the epic — the clearance's §5 item 5 /
   OQ-C1-3 class, bd 3qlq.9. */
int ext_f(int a);

int slice(int u) {
  int q = u; cq_theta(&q, 0.5);
  int r = u; cq_theta(&r, 0.3);
  int y = 5;
  if (q > 5) y = ext_f(7);
  if ((y >> 0) & 1) cq_phi(0.25);
  cq_theta(&r, 0.1);
  if ((y >> 1) & 1) cq_phi(0.25);
  cq_theta(&r, 0.1);
  if ((y >> 2) & 1) cq_phi(0.25);
  cq_theta(&r, 0.1);
  cq_theta(&y, 0.9);
  return cq_measure(r) + cq_measure(y);
}

int main(void) { (void)slice(5); return 0; }
