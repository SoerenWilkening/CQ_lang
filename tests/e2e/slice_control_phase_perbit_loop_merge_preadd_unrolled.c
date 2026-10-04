/* slice_control_phase_perbit_loop_merge_preadd_unrolled.c — the HAND-UNROLLED
   TWIN of `slice_control_phase_perbit_loop_merge_preadd.c` (bd
   test_C_libtooling-3qlq Inc 1, the FOURTH C-1 round, finding F-I2-1).

   Byte-identity of the two goldens is the witness, checked by the ctest entry
   `e2e-phase-perbit-loop-merge-preadd-twin-identical`. It was 44 lines vs 52 on
   `main` a3c1513; it is 52 = 52 now. Nothing else about the program differs —
   same K, same angles, same registers, same merge, same preheader `add`. */
int slice(void) {
  int q = 3, p = 7, r = 9;
  cq_theta(&q, 0.5);
  cq_theta(&p, 0.25);
  cq_theta(&r, 0.3);
  int m = (q > 5) ? p : r;
  m = m + 7;
  if ((m >> 0) & 1) cq_phi(0.7);
  if ((m >> 1) & 1) cq_phi(0.7);
  if ((m >> 2) & 1) cq_phi(0.7);
  if ((m >> 3) & 1) cq_phi(0.7);
  return cq_measure(m);
}

int main(void) { (void)slice(); return 0; }
