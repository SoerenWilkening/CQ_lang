#include "CQ.h"
/* cq-3gdk: a load at another constant offset of a re-executed index may read the stored rail (p[-1] next trip is this trip's *p): measured (review w2a-slotsfix-n1 l1). */
int measured_reindex(int n) {
  int x = 0; cq_theta(&x, 0.5);
  int a[4];
  a[0] = x + 7;
  int r = 0;
  for (int i = 1; i < 4; i++) { int *p = &a[i]; r += cq_measure(p[-1]); *p = x + i; }
  return r;
}
