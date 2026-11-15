/* tests/loops-cutoff probe (cq-9kcq S11; CR rule 14): a trip-local classically bounded loop in a K-loop's trip (a sub-unit
 * of the rolled region, its reverse in the trip), its value read only by a quantum branch with a phase arm. §6-checked
 * against its C program. Regenerate ksub.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec ksub.c -o ksub.O1.ll */
#include "CQ.h"
/* a trip-local classically bounded loop in a K-trip: its value read only by a quantum branch with a phase arm */
int ks_phase(int x0, int m0, double th) {
  int m = m0 & 3;
  int x = x0; cq_theta(&x, th);
  int i = 0;
  do {
    int t = 0;
    for (int k = 0; k < m; k++)
      t += (x >> k) & 3;
    if (t == 2)
      cq_phi(th);
    i++;
  } while ((x >> (i + 8)) & 1);
  return cq_measure(i);
}
