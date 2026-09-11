// K03 — DELTA COMPLETENESS: a curated reversible intrinsic consumer.
#include <stdio.h>
extern void cq_sink_probe(int);
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  cq_sink_probe((int)__builtin_bswap32((unsigned)m));
  printf("%d %d\n", cq_measure(a), n);
  return 0;
}
