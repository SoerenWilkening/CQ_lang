/* tests/loops-cutoff mixed conditions and classical choices inside a K-trip (CR rules 8, 9 with rule 14).
 * (a) cq-kbygn: a branch condition `C && Q` inside a trip is factored on its Boolean function; C stays a classical
 *     branch in every trip copy around the quantum part (rule 8), so where C is false the arm emits nothing.
 * Each entry is checked §6 against its own C program (cqcheck user); run_probes.py --br-in counts the `br`.
 * Regenerate trip_factor.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_factor.c -o trip_factor.O1.ll */
#include "CQ.h"

/* (a) A store behind `c && q`. */
unsigned pa_mixed(unsigned x0, double th, unsigned k, int c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  while (x > k) {
    x >>= 1;
    if ((c & 1) && y > x) *f ^= 5;
  }
  return cq_measure(*f) * 16 + cq_measure(x);
}

/* (b) The bead's reproducer (trip_cbr.c pf_nested with no store before the sub-loop): -O1 joins the classical test
 *     with the sub-loop's guard into one `select i1 c, q, false`. */
unsigned pb_nested(unsigned x0, double th, unsigned k, int c, unsigned z0) {
  unsigned x = x0, z = z0; cq_theta(&x, th); cq_theta(&z, th);
  unsigned cell = 0, n = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  while (x > k) {
    x >>= 1;
    if (c & 1) {
      unsigned w = z;
      while (w > x) { w >>= 1; n += 2; }
    }
    if (!(c & 2)) continue;
    *f += n + 1;
  }
  return cq_measure(n) * 256 + cq_measure(*f);
}
