#include <stdlib.h>
__attribute__((noinline)) double w(double m, double k) {
  double q = cq_theta(m, .5); double z = cq_measure(q);
  return k + z + 1.0;
}
int main(int c, char **v) { int m = atoi(v[1]); return (int)w((double)(m & 7), (double)m); }
