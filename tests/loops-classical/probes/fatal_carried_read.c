/* cq-igqp: a record before the loop reads the rotated initial rail and is undone after the loop. cq-lower must stop (cq::unimplemented, see run_loops_classical.py FATAL). Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec fatal_carried_read.c -o fatal_carried_read.O1.ll */
#include "CQ.h"
/* A record before the loop reads the register the loop rotates; its garbage is read in the trip. */
int p38_read(int x0, int n, double th) {
  int x = x0;
  cq_theta(&x, th);
  int a = x * 5;
  int r = 0;
  for (int i = 0; i < n; i++) {
    r ^= cq_measure(a + i);
    cq_theta(&x, th);
  }
  return r ^ cq_measure(x);
}
