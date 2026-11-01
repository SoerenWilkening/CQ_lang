/* cq-igqp: the rotation under a classical branch of the trip: the initial rail is entangled on some paths only. cq-lower must stop (cq::unimplemented, see run_loops_classical.py FATAL). Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec fatal_carried_arm.c -o fatal_carried_arm.O1.ll */
#include "CQ.h"
/* The rotation under a classical branch inside the trip. */
int p38_arm(int x0, int n, double th) {
  int x = x0;
  cq_theta(&x, th);
  x = x * 3 + 1;
  for (int i = 0; i < n; i++)
    if (i & 1)
      cq_theta(&x, th);
  return cq_measure(x);
}
