#include <stdlib.h>
/* r1B v1 — the clone call INSIDE a tainted value arm, in the chain's window. */

__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  int w = cq_theta(m & 3, 0.3);
  int s = w;
  if (w == 1) s = q + 1;
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s);
  q = cq_theta(q, 0.7);
  return ms + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
