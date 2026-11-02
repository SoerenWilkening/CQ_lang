#include "CQ.h"
/* cq-e5lj (CR rules 20, 26, 63): a local union read across its members (a byte of an int member) is a value object
   of byte cells, a bit view; main stopped at "a slot record access that is not exactly one field". */
int view_c(int x0, double th) {
  union { int i; unsigned char c[4]; } u;
  int x = x0; cq_theta(&x, th);
  u.i = x;
  u.c[2] = 7;
  return cq_measure(u.i) + cq_measure(u.c[1]);
}
