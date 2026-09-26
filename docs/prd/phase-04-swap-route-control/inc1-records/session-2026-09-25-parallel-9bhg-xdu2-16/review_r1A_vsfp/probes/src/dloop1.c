#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int p = 1;
  for (int i = 0; i < 4; i++) p = p * 3 + q;
  int t = h(p, m);
  q = cq_theta(q, .7);
  return t + cq_measure(q);
}
