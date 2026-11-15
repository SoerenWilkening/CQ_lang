/* tests/loops-cutoff mixed conditions and classical choices inside a K-trip (CR rules 8, 9 with rule 14).
 * (a) cq-kbygn: a branch condition `C && Q` inside a trip is factored on its Boolean function; C stays a classical
 *     branch in every trip around the quantum part (rule 8), so where C is false the arm emits nothing.
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

/* (c) cq-o5tjh (CR rule 9: "A `select` or `phi` whose condition (or choice of incoming edge) is purely classical is a
 *     classical `select`/`phi` over the handles, no gate"): the merge of the two classical arms is a classical select
 *     in every trip, not a select template on a seed of the classical condition. */
unsigned pc_choice(unsigned x0, double th, unsigned k, int c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned acc = 1, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  while (x > k) {
    x >>= 1;
    unsigned v;
    if (c & 1) { v = y * 3 + x; cq_phi(0.25); } else { v = y ^ x; *f += 2; }
    acc = acc * 5 + v;
  }
  return cq_measure(acc) * 64 + cq_measure(*f);
}

/* (d) cq-o5tjh: a classically bounded sub-loop of the trip behind a classical condition and behind a mixed one: the
 *     classical part is the branch around it, its trip rail the quantum part alone (no seed of the classical term). */
unsigned pd_csub(unsigned x0, double th, unsigned k, int c, unsigned m, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned acc = 0, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  while (x > k) {
    x >>= 1;
    if (c & 1) { for (unsigned i = 0; i < (m & 3); i++) *f += y ^ i; }
    if ((c & 2) && y > x) { for (unsigned i = 0; i < (m & 3); i++) *f ^= x + i; }
    acc = acc * 3 + x;
  }
  return cq_measure(acc) * 256 + cq_measure(*f);
}

/* (e) cq-o5tjh: a K-loop of a K-loop's exit arm behind a classical condition of the arm. */
int pe_arm(int x0, double th, int c) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 1, r, j;
  do {
    acc = acc * 3 + i;
    i++;
    if ((x >> (i + 8)) & 1)
      goto found;
  } while ((x >> i) & 1);
  r = acc;
  goto join;
found:
  j = i;
  if (c & 1)
    while ((x >> (j + 16)) & 1)
      j++;
  r = acc + j * 7;
join:
  return cq_measure(r);
}
