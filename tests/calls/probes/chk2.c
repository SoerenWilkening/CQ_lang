/* tests/calls probe, cq-00mrg (rule 16): __sprintf_chk is plain sprintf. */
#include "CQ.h"
#include <stdio.h>
int chk2(int x, double th) {
  char d[16];
  cq_theta(&x, th);
  sprintf(d, "%d", x & 7);
  return cq_measure(d[0]);
}
