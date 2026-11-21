#include "CQ.h"
/* GMP __gmpn_jacobi_base's loop nest (mpn/generic/jacobi_base.c) with only `bit` quantum (the 001 arrangement):
 * the inner loop's exits `return 0` and `goto done` both leave the outer loop (unifySubLoopExits' hub), so the outer,
 * classically bounded loop has one exiting block with two live exit blocks; `done` is also entered before the loop. */
int jac(unsigned long a, unsigned long b, int bit0, double th) {
  int bit = bit0; cq_theta(&bit, th);
  if (a == 0) return 0;
  while ((a & 1) == 0) { bit ^= (int)(b ^ (b >> 1)); a >>= 1; }
  if (a == 1) goto done;
  for (;;) {
    for (;;) {
      a -= b;
      if (a == 0) return 0;
      do { a >>= 1; bit ^= (int)(b ^ (b >> 1)); } while ((a & 1) == 0);
      if (a == 1) goto done;
      if (a < b) break;
    }
    { unsigned long t = a; a = b; b = t; bit ^= (int)(a & b); }
  }
done:
  return 1 - (bit & 2);
}
