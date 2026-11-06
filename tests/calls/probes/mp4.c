/* tests/calls probe. */
#include "CQ.h"
/* rule 22, host-resident destination: memset_pattern16 stays the host call, its loads classical */
int mp4(int x, int n, double th) {
  int a[8];
  cq_theta(&x, th);
  for (int i = 0; i < 8; i++) a[i] = 0x01020304;
  return cq_measure(a[n & 7] + x);
}
