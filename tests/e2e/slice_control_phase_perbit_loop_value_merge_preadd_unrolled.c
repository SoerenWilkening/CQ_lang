/* slice_control_phase_perbit_loop_value_merge_preadd_unrolled.c — the
   HAND-UNROLLED TWIN of `slice_control_phase_perbit_loop_value_merge_preadd.c`
   (bd test_C_libtooling-3qlq, the FOURTH C-1 round rebased onto the landed
   Increment 2).

   Byte-identity of the two goldens is the witness, checked by the ctest entry
   `e2e-phase-perbit-loop-value-merge-preadd-twin-identical`. It was 52 lines vs
   60 on `main` 258d974; it is 60 = 60 here. Nothing else about the program
   differs — same K, same angles, same registers, same Inc-2 value arm, same
   preheader `add`. */
int slice(void) {
  int q = 3, p = 7;
  q = cq_theta(q, 0.5);
  p = cq_theta(p, 0.25);
  if (q > 3) { p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2; }
  p = p + 7;
  if ((p >> 0) & 1) cq_phi(0.7);
  if ((p >> 1) & 1) cq_phi(0.7);
  if ((p >> 2) & 1) cq_phi(0.7);
  if ((p >> 3) & 1) cq_phi(0.7);
  return cq_measure(p);
}

int main(void) { (void)slice(); return 0; }
