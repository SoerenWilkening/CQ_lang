#include <stdlib.h>
/* r1B l2 — clone CONSUMER of a chain rail inside a classically-bounded loop, rail
   minted outside (f23's shape) with the chain's kickback AFTER the loop and a second
   Ry on q after that. */
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  int acc = 0;
  for (int i = 0; i < m; i++) acc += cq_measure(h(i, p));
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, 0.7);
  return acc + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
