#include "CQ.h"
/* jac.c's loop nest in a clone (the library's 001 arrangement of GMP __gmpn_jacobi_base: a, b classical, bit quantum),
 * and red1.c's single loop (two exiting blocks: the existing c1Arm form) likewise, for comparison. */
__attribute__((noinline)) int jacl(unsigned long a, unsigned long b, int bit) {
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
int jacw(unsigned long a, unsigned long b, int bit0, double th) {
  int bit = bit0; cq_theta(&bit, th);
  return jacl(a, b, bit);
}
__attribute__((noinline)) int red1l(unsigned a, unsigned b, int x) {
  if (a == 0) return 0;
  if (a == 1) goto arm;
  for (;;) {
    a = (a >> 1) ^ b;
    if (a == 0) return 0;
    x ^= (int)a;
    if (a & 1) break;
  }
arm:
  return 1 - (x & 2);
}
int red1w(unsigned a, unsigned b, int x0, double th) {
  int x = x0; cq_theta(&x, th);
  return red1l(a, b, x);
}
