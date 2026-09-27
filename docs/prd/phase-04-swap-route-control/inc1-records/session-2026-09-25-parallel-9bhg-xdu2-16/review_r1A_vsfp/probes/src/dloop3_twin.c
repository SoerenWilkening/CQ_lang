#include <stdlib.h>

int main(int c, char **v) {
  int m = atoi(v[1]); int n = atoi(v[2]);
  int q = cq_theta(m & 7, .5);
  int p = 1;
  for (int i = 0; i < n; i++) p = p * 3 + q;
  int t = m + 1;
  return t + cq_measure(q);
}
