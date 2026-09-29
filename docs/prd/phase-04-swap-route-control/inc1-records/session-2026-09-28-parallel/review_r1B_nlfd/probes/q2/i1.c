#include <stdlib.h>
double h(double a);
int main(int c, char **v) {
  int m = atoi(v[1]); double x = (double)(m & 7) - 3.0;
  double q = cq_theta(x, .5); double r = h(q);
  return (int)cq_measure(r) + (int)cq_measure(q);
}
