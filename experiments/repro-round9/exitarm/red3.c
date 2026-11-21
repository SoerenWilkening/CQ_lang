#include "CQ.h"
/* red1.c without the paths from before the loop into C and into the arm: the c1Arm form alone (control). */
int red3(unsigned a, unsigned b, int x0, double th) {
  int x = x0; cq_theta(&x, th);
  for (;;) {
    a = (a >> 1) ^ b;
    if (a == 0) return 0;
    x ^= (int)a;
    if (a & 1) break;
  }
  return 1 - (x & 2);
}
