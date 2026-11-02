/* cq-igqp: a seed rotated by the trip, freed by the reverse loop. cq-lower lowers it (cq-l56v; was a fatal probe). Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec fatal_carried_seed.c -o fatal_carried_seed.O1.ll */
#include "CQ.h"
/* A classical initial value: the loop's seed is the rail the trip rotates. */
int p38_seed(int n, double th) {
  int x = 0;
  for (int i = 0; i < n; i++)
    cq_theta(&x, th);
  return cq_measure(x);
}
