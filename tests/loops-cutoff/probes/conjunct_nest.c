/* tests/loops-cutoff probe, owner ruling Q10 (CR rule 14, rule 8) for a K-loop nested in a classically bounded loop
 * (loops-classical's walk, exits::lowerNestedCutoff). (a) The pre-header guard `C && Q` is trip 0's test: its classical
 * conjunct is a real branch before trip 0, not dropped from the seed (review finding R1 n1: trip 0 ran where C was
 * false). (b) The chain's end through the tests' joins is a_K, kept arm by arm in every trip of the outer loop (the
 * reverse loop mirrors each segment, so a kept merge does not keep its arm there). Each entry is checked §6 against its
 * own C program (cqcheck user) at K = 4, a_K per activation included.
 * Regenerate conjunct_nest.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec conjunct_nest.c -o conjunct_nest.O1.ll */
#include "CQ.h"

/* (a) `for (; c && q; )`: -O1's guard `(m & 1) && y > 2` before the rotated loop */
unsigned cn_guard(unsigned x0, double th, unsigned m, unsigned n) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  for (unsigned k = 0; k < (n & 3); k++) {
    unsigned y = x + k, i;
    for (i = 0; ((m >> i) & 1) && y > 2; i++) { y -= 3; s = s * 5 + y; }
  }
  return cq_measure(s);
}
/* (b) `do ... while (c && q)`: trip 0 unconditional, C at the later tests; a_K where C held at every test */
unsigned cn_do(unsigned x0, double th, unsigned m, unsigned n) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  for (unsigned k = 0; k < (n & 3); k++) {
    unsigned y = x + k, i = 0;
    do { y -= 3; s = s * 5 + y; i++; } while (((m >> i) & 1) && y > 2);
  }
  return cq_measure(s);
}
