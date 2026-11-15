/* tests/loops-classical probe (CR rules 6, 8, 14; cq-kk46l): a classical branch inside a classically bounded
 * loop's trip. kc_reg, kc_sel: inside a quantum-exit loop that is one node of the trip (rule 14 nested K-loops), the
 * branch on (c & 1) stays a real `br` in the rolled K trip (rule 8: no seed of c); each block it makes is a segment of
 * the trip, reversed on the path that ran it. kc_reg's carried acc is a rule-6 register whose update lies past the
 * branches' joins (cq-bqbty); kc_sel's is no bijection (the reverse loop undoes it). Each entry §6-checked.
 * Regenerate knest_cbr.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec -include CQ.h knest_cbr.c -o knest_cbr.O1.ll */
#include "CQ.h"
unsigned kc_reg(unsigned x0, double th, unsigned k, int c, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned acc = 0, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  for (unsigned i = 0; i < (m & 3); i++) {
    unsigned y = x + i;
    while (y > k) { y >>= 1; if (c & 1) *f ^= y; }
    acc = acc * 3 + y;
  }
  return cq_measure(acc) * 256 + cq_measure(*f);
}
unsigned kc_sel(unsigned x0, double th, unsigned k, int c, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned acc = 0, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  for (unsigned i = 0; i < (m & 3); i++) {
    unsigned y = x + i;
    while (y > k) { y >>= 1; if (c & 1) *f ^= y; }
    acc = acc * (y | 1) + (acc >> 3);
  }
  return cq_measure(acc) * 256 + cq_measure(*f);
}
