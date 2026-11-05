#include <signal.h>
static int hits;
static void h(int s) { hits += s; }
int raise_read(int x0, double tx, int k) {
  int x = x0;
  cq_theta(&x, tx);
  signal(SIGUSR2, h);
  void (*old)(int) = signal(SIGUSR1, h);
  int r = 0;
  if (x > k)
    r = raise(SIGUSR1);
  return cq_measure(x) + cq_measure(r) + cq_measure(hits) + (old != 0);
}
