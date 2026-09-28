/* r1A probe B4: clone reads the BORROWED PARENT q inside a runtime-trip classical loop in the window. */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int p = q * 3;
  int u = p ^ q;
  int ms = 0;
  for (int i = 0; i < m; i++) ms += cq_measure(h(i, q));
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7);
  return ms + cq_measure(q);
}
