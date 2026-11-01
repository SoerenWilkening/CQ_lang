/* tests/loops-cutoff mixed-exit probes (cq-s7c4, CR rule 14): a quantum exit test with a classical disjunct.
 * The disjunct is a classical bound only when it bounds the trip count on its own (LLVM computes its count):
 * mx_stop's loop-invariant `stop` bounds nothing (case 2, K cutoff; before cq-s7c4 case 3, and the lowered loop
 * branched on `stop` alone and never exited when stop == 0); mx_bound's `i < n` does (case 3).
 * Each entry is checked §6 against its own C program (cqcheck user). Regenerate mixed_exit.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec mixed_exit.c -o mixed_exit.O1.ll */
#include "CQ.h"
int mx_stop(int x0, double th, int stop) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  do { acc = acc * 3 + i; i++; } while (!(stop || (((x | 16) >> i) & 1)));
  return cq_measure(acc);
}
int mx_bound(int x0, double th, int n) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  do { acc = acc * 3 + i; i++; } while (!(i >= n || ((x >> i) & 1)));
  return cq_measure(acc);
}
