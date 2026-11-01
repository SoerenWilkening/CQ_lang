/* cq-igqp: the initial value is read after the loop, where its rail is rotated. cq-lower must stop (cq::unimplemented, see run_loops_classical.py FATAL). Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec fatal_carried_sunk.c -o fatal_carried_sunk.O1.ll */
#include "CQ.h"
/* As above, with the garbage read after the loop: -O1 sinks the record past the loop, where it would read the
 * rotated rail (cq::unimplemented, the pre-rotation value read after an in-place rotation). */
int p38_sunk(int x0, int n, double th) {
  int x = x0;
  cq_theta(&x, th);
  int a = x * 5;
  for (int i = 0; i < n; i++)
    cq_theta(&x, th);
  return cq_measure(a + 1) ^ cq_measure(x);
}
