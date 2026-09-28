#include <stdlib.h>
/* r2A mc2 — rhk5 x M-C late in-place (`if (f(a)==k) ...; a -= off;`), with the
   derived chain's p ALSO read by a clone call before the sub. */
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  int s = p + 1;
  q -= 3;
  q = cq_theta(q, 0.7);
  return cq_measure(s) + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
