#include "CQ.h"
#include <signal.h>
#include <stdio.h>
/* cq-a63l (CR rule 16 signal table): signal() under a quantum predicate makes the handler a merged value. */
static void h1(int s) { printf("h1 %d\n", s); }
int merged_handler(int c, int k) {
  int x = cq_theta_si32(c, 1.0);
  if (x > k)
    signal(SIGUSR1, h1);
  if (x > 2)
    raise(SIGUSR1);
  return cq_measure_si32(x);
}
