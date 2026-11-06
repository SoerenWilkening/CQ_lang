/* tests/loops-cutoff probe (CR rules 9, 14): musl mbsrtowcs' shape. Two K-loops in classical arms: the first exits into a
 * block E, the second exits into E and past it, so E is the second unit's tail and E's phi is bound by the first unit.
 * The join after E takes a constant from an edge of E, whose condition is not lowered when the earlier units run.
 * Regenerate tail_phis.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec tail_phis.c -o tail_phis.O1.ll */
#include "CQ.h"
int tp_g;
int tp_tail(int x0, long w, double th) {
  int x = x0; cq_theta(&x, th);
  long c = 0, r;
  int i = 0;
  if (w == 3) {
    for (i = 0; i < 5; i++)
      if ((x >> i) & 1) {
        r = i + 40;
        goto ret;
      }
    r = 50;
    goto ret;
  }
  if (w == 1) {
    while ((x >> i) & 1) {
      c += 1;
      i++;
    }
    goto err;
  }
  if (w == 2) {
    for (;;) {
      if ((x >> (i + 8)) & 1) {
        r = c + 5;
        goto ret;
      }
      if (!((x >> i) & 1))
        goto err;
      c += 2;
      i++;
    }
  }
  r = 7;
  goto ret;
err:
  if ((x >> 20) & 1) {
    r = c + 1;
  } else {
    if ((x >> 21) & 1)
      tp_g = 1;
    r = -1;
  }
ret:
  return cq_measure(r);
}
