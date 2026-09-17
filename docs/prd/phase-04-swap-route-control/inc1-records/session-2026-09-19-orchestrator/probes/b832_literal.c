/* bd 832l's LITERAL subject: a loop-carried _Bool with a CONSTANT seed, mutated
   IN PLACE by a chained theta — NOT a merge %out. */
#include "CQ.h"
volatile int N = 3;
int main(void){ bool b = 0; int n = N;
  for (int i = 0; i < n; ++i) b = cq_theta(b, 0.5);
  return cq_measure(b); }
