#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]); int n = atoi(v[2]);
  bool b = cq_theta((bool)(m & 1), .5);
  int s = m;
  for (int i = 0; i < n; ++i) {
    b = cq_theta(b, 0.5);
    if (b) s -= 7;
  }
  int t = h(s, m);
  return t + cq_measure(b);
}
