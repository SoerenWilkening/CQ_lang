#include <stdlib.h>

int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int r = cq_measure(q) * 2 + 1;
  int t = m + 1;
  int q2 = cq_theta(m & 3, .9);
  int t2 = t + 1;
  return t2;
}
