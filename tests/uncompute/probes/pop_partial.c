/* tests/uncompute probe (cq-4lqy; CR §1.3, §0): a POP whose value rail is rotated on one classical path only: the POP,
 * the earlier POPs and the bus release run under the same run flag (kept together where the rotation ran; was:
 * "a QRAM store whose POP reads a rail a non-diagonal gate hits on some paths only").
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec pop_partial.c -o pop_partial.O1.ll */
#include <stdlib.h>
#include "CQ.h"
int pp(unsigned k0, unsigned char v0, int c, double t) {   /* a POP whose value rail is rotated on one classical path */
  unsigned k = k0; cq_theta(&k, 1.0);
  unsigned char v = v0; cq_theta(&v, 1.0);
  unsigned char *a = malloc(4);
  a[0] = 7;
  a[k & 3] = v;
  unsigned char r = a[1];
  int m = cq_measure(r);
  if (c) cq_theta(&v, t);
  unsigned char z = a[2];
  return m + cq_measure(z) + cq_measure(k);
}
