#include <stdlib.h>
/* r1B l1 — the clone call in a CLASSICALLY-bounded loop body inside the chain's
   window; each trip's clone result is measured in the trip. */
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  int acc = 0;
  for (int i = 0; i < m; i++) acc += cq_measure(h(i, q));
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, 0.7);
  return acc + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
