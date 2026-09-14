/* Control for r01: the straight-through incoming is INITIALIZED to a non-zero
   constant while the seed is uninitialized. F1 clause 1 must still fail. */
#include <CQ.h>
int f(int c) {
  _Bool x;
  _Bool r = 1;
  if (c) r = cq_theta(x, 0.5);
  return cq_measure(r);
}
