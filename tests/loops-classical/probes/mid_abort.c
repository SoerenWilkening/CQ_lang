/* tests/loops-classical probe (cq-uepm8, CR rules 14 case 3, 16): a quantum exit at the header, then a classical test into a
 * noreturn arm mid-trip (the loop's bound). In the trip the C program does not run (its header test already left) the
 * classical exit into the arm must see the captures with that trip's header exit taken in. Regenerate mid_abort.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec mid_abort.c -o mid_abort.O1.ll */
#include "CQ.h"
void abort(void);
int g[8];
int ma_sum(unsigned x0, double th, unsigned y) {
  unsigned x = x0;
  cq_theta(&x, th);
  x &= 31;
  int s = 0;
  unsigned k = 0;
  while (x != 0) {
    if (x == 6)
      abort();
    g[x & 7] += 1;
    if (k == (y & 3))
      abort();
    s += (int)x;
    x >>= 1;
    k++;
  }
  return s + g[1] + 2 * g[3];
}
