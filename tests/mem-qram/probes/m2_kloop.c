#include "CQ.h"
/* M2 in a K-loop (CR rules 14 case 2, 18, 21): a clone copies a quantum-terminated string into its caller's QRAM
   through a triple formal; the copy loop's exit is quantum, so its K trips are unrolled, one store per trip. */
__attribute__((noinline)) static void cpy(int *d, const int *s) {
  while ((*d++ = *s++))
    ;
}
int m2_kloop(unsigned x0, double th, int k) {
  unsigned x = x0;
  cq_theta(&x, th);
  int src[6] = {(int)(x & 3), (int)((x >> 2) & 1), 5, 0, 0, 0};
  int dst[8] = {k, k + 1, k + 2, k + 3, k + 4, k + 5, k + 6, k + 7};
  dst[x & 7] = 9;                  /* a quantum-index store: dst is a QRAM */
  cpy(dst + 1, src);
  return cq_measure(dst[1]) * 10000 + cq_measure(dst[2]) * 100 + cq_measure(dst[(x >> 1) & 7]);
}
