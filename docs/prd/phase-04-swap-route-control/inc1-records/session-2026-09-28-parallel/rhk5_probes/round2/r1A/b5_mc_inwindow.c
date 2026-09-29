/* r1A probe B5: an M-C candidate `q -= 5` INSIDE the chain's window, after the clone call. */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int p = q * 3;
  int u = p ^ q;
  int s = h(m, q);
  q -= 5;
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s);
  q = cq_theta(q, .7);
  return ms + cq_measure(q);
}
