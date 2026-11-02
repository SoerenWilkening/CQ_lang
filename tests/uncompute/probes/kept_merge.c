/* tests/uncompute probe (cq-lshe, CR rule 9, §0): a kept classical merge keeps the arm it chose; the other arm
 * is cleaned under the same classical choice.
 *   ks: a select on a classical c over two garbage rails, measured.
 *   kp: the same as a phi of two arms, the unchosen one read again after the join.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec kept_merge.c -o kept_merge.O1.ll */
#include "CQ.h"
int ks(int a, int c) {
  int x = a; cq_theta(&x, 1.0);
  int y = c ? (x & 6) : (x | 1);
  return cq_measure(y);
}
int kp(int a, int c, int d) {
  int x = a; cq_theta(&x, 1.0);
  int t = x & 6, y;
  if (c) y = t; else y = x | 1;
  int r = cq_measure(y);
  if (d) r += cq_measure(t * 7);
  return r;
}
int kq(int a, int c) {
  int x = a; cq_theta(&x, 1.0);
  int t = x & 6, y;
  if (c) y = t; else y = x | 1;
  int r = cq_measure(y);
  return r + cq_measure(t * 7);
}
