/* tests/loops-classical probe (CR rule 6, rule 8; cq-bqbty): a carried value of a classically bounded loop whose
 * bijective update lies past a real classical join of the trip (`if (c & 1) *f ^= y;` before it) is a rule-6 register:
 * the old rail is cleaned per trip in the join's segment. §6-checked.
 * Regenerate r6_join.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec -include CQ.h r6_join.c -o r6_join.O1.ll */
#include "CQ.h"
unsigned r6_join(unsigned x0, double th, int c, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned acc = 0, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  for (unsigned i = 0; i < (m & 3); i++) {
    unsigned y = x + i;
    if (c & 1) *f ^= y;
    acc = acc * 3 + y;
  }
  return cq_measure(acc) * 256 + cq_measure(*f);
}
