#include "CQ.h"
/* cq-0kji: a narrower store merges into the latest value covering its bytes, not the latest store overlapping them (review w2a-slotsfix-n1 c3, t1). */
union lv { long double e; unsigned char b[16]; unsigned short h[8]; unsigned w[4]; };
unsigned view_merge(long double x0, double th, unsigned short k, unsigned char a, unsigned char b) {
  long double x = x0; cq_theta(&x, th);
  union lv u;
  u.h[5] = k;
  u.e = x;
  u.b[8] = a;
  u.b[9] = b;
  return cq_measure(u.w[2]);
}
