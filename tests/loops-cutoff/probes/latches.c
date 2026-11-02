/* tests/loops-cutoff latch probes (cq-b58q, CR rule 14 "`continue` ... same chain"): K-loops with several back
 * edges (a `continue` straight to the header), an exit from one latch, and an invariant pointer into a slot array.
 * Each entry is checked §6 against its own C program (cqcheck user). Regenerate latches.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec latches.c -o latches.O1.ll */
#include "CQ.h"
/* Two back edges: the `continue` arm and the fall-through, the exit tested at the bottom. */
int ml_continue(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  for (;;) {
    i++;
    if ((x >> (i + 3)) & 1) {
      acc = acc * 5 + 1;
      if (acc & 64) break;
      continue;
    }
    acc = acc * 3 + i;
    if (!((x >> i) & 1)) break;
  }
  return cq_measure(acc);
}
/* A while loop whose `continue` skips a phase. */
int ml_phase(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0;
  while ((x >> i) & 1) {
    i++;
    if ((x >> (i + 4)) & 1) continue;
    cq_phi(0.125);
  }
  return cq_measure(x);
}
