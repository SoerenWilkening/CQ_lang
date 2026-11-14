/* tests/loops-cutoff probe (cq-lv2ba; CR rules 14, 16): a classically bounded sub-loop with an abort arm inside a K-trip,
   behind a classical condition of the outer trip (i & 1). The inner counter n is classical by taint, but the sub-loop's
   only way on is its quantum exit, so after it n is a rail; the skip path gives it a |0> seed, not the constant 0.
   Regenerate sub_abort_skip.O1.ll:
   clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec sub_abort_skip.c -o sub_abort_skip.O1.ll */
#include "CQ.h"
#include <stdlib.h>
int sub_abort_skip(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1,b4=1,b5=1,b6=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);cq_theta(&b4,1.0);cq_theta(&b5,1.0);cq_theta(&b6,1.0);
  unsigned v = b0|b1<<1|b2<<2|b3<<3|b4<<4, w = b5|b6<<1; int r=0; unsigned i=c;
  while (v&1) { v>>=1;
    if (i&1) { unsigned u = w | (v<<2); int n = 0; while (u&1) { u>>=1; n++; if (n == 3) abort(); } r += n; }
    r = r*3 + 1;
    i += 1; }
  return r;
}
