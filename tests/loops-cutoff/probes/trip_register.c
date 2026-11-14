/* tests/loops-cutoff probe, cq-bxikv (CR rule 8: a purely classical condition is a classical branch, also in a trip; rule
 * 14: a K-loop's carried register): a register rotated in place behind a classical branch of every trip is the same rail
 * on the path that ran the rotation and on the one that skipped it, so the trip carries it in place. Before: the skip
 * path's |0> seed made it a classical select of two rails, copied per trip by the trip's select and rotated as the copy
 * (3 rails leaked at exit). Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec trip_register.c -o trip_register.O1.ll */
#include "CQ.h"
unsigned w_d(unsigned x0, double th, unsigned k, int c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  while (x > k) { x >>= 1; if (c & 2) cq_theta(&y, 0.25); }
  return cq_measure(y);
}
unsigned w_e(unsigned x0, double th, unsigned k, int c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  while (x > k) { x >>= 1; if (c & 2) cq_theta(&y, 0.25); else cq_theta(&y, 0.5); }
  return cq_measure(y);
}
