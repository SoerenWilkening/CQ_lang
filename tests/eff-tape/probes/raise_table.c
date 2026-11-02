#include "CQ.h"
#include <signal.h>
/* cq-a63l (CR rule 16 signal table): the handler read from the host table at run time and dispatched over the
   module's candidates (rule 19). */
#include <stdio.h>
static void h1(int s) { printf("h1 %d\n", s); }
static void h2(int s) { printf("h2 %d\n", s); }
int two_handlers(int c, int k) {
  signal(SIGUSR1, k ? h1 : h2);
  int x = cq_theta_si32(c, 1.0);
  if (x > 3)
    raise(SIGUSR1);
  return cq_measure_si32(x);
}
int runtime_sig(int c, int s) {
  signal(SIGUSR2, h1);
  int x = cq_theta_si32(c, 1.0);
  if (x > 3)
    raise(s == 1 ? SIGUSR2 : SIGWINCH);
  return cq_measure_si32(x);
}
