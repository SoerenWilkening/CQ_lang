/* r1A probe A4: can a clone reach the caller's register through MEMORY rather than a
   formal? main stores q into a local array whose address is passed to the callee. */
#include <stdlib.h>
int h(int a, int k, int *pb);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int b[2];
  int q = cq_theta(m & 7, .5);
  b[0] = q; b[1] = m;
  int p = q * 3;
  int u = p ^ q;
  int s = h(m, q, b);
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s);
  q = cq_theta(q, .7);
  return ms + cq_measure(q);
}
