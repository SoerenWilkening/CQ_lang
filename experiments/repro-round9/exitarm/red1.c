#include "CQ.h"
/* A loop with two classical exits: one returns 0, the other enters an arm also reached from before the loop;
 * the arm computes a quantum value merged at the return (GMP __gmpn_jacobi_base, arrangement 001). */
int red1(unsigned a, unsigned b, int x0, double th) {
  int x = x0; cq_theta(&x, th);
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
/* Nested: the inner loop's two exits leave the outer loop too (jacobi_base's own shape). */
int red2(unsigned a, unsigned b, int x0, double th) {
  int x = x0; cq_theta(&x, th);
  if (a == 0) return 0;
  if (a == 1) goto arm;
  for (;;) {
    for (;;) {
      a = (a >> 1) ^ b;
      if (a == 0) return 0;
      x ^= (int)a;
      if (a & 1) goto arm;
      if (a & 4) break;
    }
    b = b >> 1;
  }
arm:
  return 1 - (x & 2);
}
