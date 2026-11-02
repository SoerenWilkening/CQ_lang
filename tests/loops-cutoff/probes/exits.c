/* tests/loops-cutoff exit probes (cq-b58q, CR rule 14: the exit value is quantum, it depends on which trip exited):
 * reads after a K-loop that the single-exit forms cannot express go through the general exit capture (a rail per
 * value taking each trip's value where the trip exits), under a classical skip of the loop too.
 * Each entry is checked §6 against its own C program (cqcheck user). Regenerate exits.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec exits.c -o exits.O1.ll */
#include "CQ.h"
/* An exit phi with a loop-invariant incoming on the exit edge, the loop under a classical condition. */
int ce_found(int x0, double th, int c) {
  int x = x0; cq_theta(&x, th);
  int found = 0;
  if (c > 0) {
    int i = 0;
    do { cq_phi(0.5); i++; } while ((x >> i) & 1);
    found = 5;
  }
  return cq_measure(found + x);
}
/* A header-tested loop whose value read after it is computed from the classical induction. */
int ce_region(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  while ((x >> i) & 1) { acc = acc * 3 + 1; i++; }
  return cq_measure(acc * 2 + i);
}
/* A body value of a header-tested loop read after it. */
int ce_body(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, t = 0, i = 0;
  while ((x >> i) & 1) { t = acc ^ (i * 5); acc = acc * 3 + t; i++; }
  return cq_measure(t);
}
