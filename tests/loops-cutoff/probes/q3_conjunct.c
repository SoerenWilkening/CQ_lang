/* tests/loops-cutoff probe (review R1 t3, bead cq-nmzv3; rulings Q3 part 2, Q10; CR rules 2, 8): a measurement behind
   `c && q`. clang -O1 makes the condition one select(c == 0, true, q == 0); where c == 0 the classical conjunct alone
   leaves the path to the site, a classical condition, so a measurement there is a failure; where c != 0 the quantum
   conjunct decides, and the circuit's unconditional measurement (rule 2) is accepted.
   run_probes.py MUTANTS: the lowering's classical br on c dropped (the measurement on every input) is rejected, for mix
   (the conjunct form) and mixc (c alone).
   Regenerate q3_conjunct.O1.ll:
   clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec q3_conjunct.c -o q3_conjunct.O1.ll */
#include "CQ.h"
int mix(unsigned c, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  int s = 0;
  if (c && (x & 1)) s += cq_measure(x + 3) & 0;
  return s;
}
int mixc(unsigned c, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  int s = 0;
  if (c) s += cq_measure(x + 3) & 0;
  return s;
}
