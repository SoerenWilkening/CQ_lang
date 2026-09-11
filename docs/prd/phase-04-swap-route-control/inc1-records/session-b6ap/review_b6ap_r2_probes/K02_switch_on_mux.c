// K02 — DELTA COMPLETENESS: a `switch` on the peeled mux.
#include <stdio.h>
extern void cq_sink_probe(int);
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int r = 0;
  switch (m) { case 5: r = 11; break; case 7: r = 22; break; default: r = 33; }
  cq_sink_probe(r);
  printf("%d %d\n", cq_measure(a), n);
  return 0;
}
