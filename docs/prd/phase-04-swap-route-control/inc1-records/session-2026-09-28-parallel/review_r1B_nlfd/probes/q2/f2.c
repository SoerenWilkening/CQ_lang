#include <stdlib.h>
double h2(double a, double k);
__attribute__((noinline)) double w(double m, double k) {
  double q = cq_theta(m, .5); double p = q * 3.0; double z = cq_measure(q);
  __attribute__((musttail)) return h2(p, k + z);
}
int main(int c, char **v) { int m = atoi(v[1]); return (int)w((double)(m & 7), (double)m); }
