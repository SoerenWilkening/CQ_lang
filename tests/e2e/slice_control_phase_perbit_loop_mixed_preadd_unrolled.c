/* slice_control_phase_perbit_loop_mixed_preadd_unrolled.c — the HAND-UNROLLED
   TWIN of `slice_control_phase_perbit_loop_mixed_preadd.c` (bd
   test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round, finding F-C1-1).

   Byte-identity of the two goldens is the witness, checked by the ctest entry
   `e2e-phase-perbit-loop-mixed-preadd-twin-identical`. It was 32 lines vs 38 on
   542d588 and on the round-1 C-1 fix; it is 38 = 38 now. Nothing else about the
   program differs — same K, same angles, same registers, same preheader `add`. */
int slice(int u) {
  int q = cq_theta(u, 0.5);
  int r = cq_theta(u, 0.3);
  q = q + 7;
  if ((q >> 0) & 1) cq_phi(0.2);
  r = cq_theta(r, 0.1);
  if ((q >> 1) & 1) cq_phi(0.2);
  r = cq_theta(r, 0.1);
  if ((q >> 2) & 1) cq_phi(0.2);
  r = cq_theta(r, 0.1);
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}

int main(void) { (void)slice(5); return 0; }
