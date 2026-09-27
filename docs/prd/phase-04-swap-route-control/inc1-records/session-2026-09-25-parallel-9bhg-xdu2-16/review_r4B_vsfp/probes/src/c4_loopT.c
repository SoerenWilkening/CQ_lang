#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  int n = atoi(v[2]);
  int q = cq_theta(m & 7, .5);
  for (int i = 0; i < n; i++) {
    if (q == 5) cq_phi(0.25);
  }
  return cq_measure(q);
}
