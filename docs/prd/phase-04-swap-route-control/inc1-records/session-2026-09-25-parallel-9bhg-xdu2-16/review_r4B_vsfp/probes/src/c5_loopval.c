#include <stdlib.h>
static volatile int K = 0;
int main(int c, char **v) {
  int m = atoi(v[1]);
  int n = atoi(v[2]);
  int q = cq_theta(m & 7, .5);
  for (int i = 0; i < n; i++) {
    int r = (q > 3) ? K : 0;
    if (q == 5) cq_phi(0.25 + r);
  }
  return cq_measure(q);
}
