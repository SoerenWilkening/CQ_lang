#include <stdlib.h>
double h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m, .5);
  if (m > 3) q = cq_theta(q, .2);
  double d = h(q, m);          /* the merge phi's ONLY direct consumer: an fp-return spec site */
  return (int)cq_measure(d);
}
