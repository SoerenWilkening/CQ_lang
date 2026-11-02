#include "CQ.h"
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
/* cq-il07 (CR rules 19, 23): a twin replays a clone's fpexcept.strict host ops on classical operands, unbracketed
   ((double)k outside the arm) and BRACKETed under the quantum predicate ((double)(k + 1) in the arm); the twin
   restores the host flags it found, so the replay raises nothing. */
__attribute__((noinline)) double g(double x, long k) {
  double y = x * (double)k;
  if (x < 1.0)
    y = y + (double)(k + 1);
  return y;
}
double e_twin(double a, long k) {
  cq_theta(&a, 0.3);
  double r = g(a, k);
  return cq_measure(r + 1.0);
}
