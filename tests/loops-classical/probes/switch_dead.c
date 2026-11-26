/* tests/loops-classical probe (cq-vvjel, CR rule 14 case 1): a classically bounded loop whose body is a classical switch
 * with gotos between cases; -O1 keeps an unreachable default. The edge into that dead end is UB to take: it must not
 * become a second edge into the loop's exit block. Regenerate switch_dead.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec switch_dead.c -o switch_dead.O1.ll */
#include "CQ.h"
int sd_goto(int c0, int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int n = x, i = 0;
  while (i < 3) {
    int c = (c0 >> (2 * i)) & 3;
    i++;
    switch (c) {
    case 0: n += 1; goto L2;
    case 1: L1: n += 5; break;
    case 2: L2: n ^= 2; if (c0 & 64) goto L1; break;
    default: n -= 1; break;
    }
  }
  return cq_measure(n);
}
