// K01 — DELTA COMPLETENESS: the consumer is reached through a CLASSICAL phi in a
// LATER block (two hops from the peeled select).
#include <stdio.h>
extern void cq_sink_probe(int);
int main(int argc, char **argv) {
  (void)argv;
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int u;
  if (argc > 1) u = m; else u = m + 3;     // classical-condition phi over the mux
  cq_sink_probe(u);
  printf("%d %d\n", cq_measure(a), n);
  return 0;
}
