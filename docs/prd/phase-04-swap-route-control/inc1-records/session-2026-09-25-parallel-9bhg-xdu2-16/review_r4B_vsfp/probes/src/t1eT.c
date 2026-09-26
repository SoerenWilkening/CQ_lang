#include <stdlib.h>
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int q1 = q + 1;
  int t = atoi(v[2]);
  int r = q1;
  return cq_measure(r) + cq_measure(q1) + t;
}
