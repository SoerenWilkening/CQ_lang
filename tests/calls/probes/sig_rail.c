#include <signal.h>
static int hits;
static void h(int s) { hits += s; }
int sig_rail(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  signal(10 + (x & 1), h);
  raise(10 + (x & 1));
  return cq_measure(x) + cq_measure(hits);
}
