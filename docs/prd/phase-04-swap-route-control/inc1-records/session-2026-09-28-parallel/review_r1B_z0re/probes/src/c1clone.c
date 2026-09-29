#include <stdlib.h>
__attribute__((noinline)) int f(int s, int m) {
  int q = cq_theta(m, 0.3);
  int r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return cq_measure(r) + cq_measure(q);
}
int main(int c, char **v) {
  int a = f(atoi(v[1]), atoi(v[2]));
  int qs = cq_theta(atoi(v[1]), 0.5);
  int b = f(qs, atoi(v[2]));
  return a + b;
}
