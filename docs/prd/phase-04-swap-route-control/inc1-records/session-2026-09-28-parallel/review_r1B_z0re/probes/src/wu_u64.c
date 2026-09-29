#include <stdlib.h>
int main(int c, char **v) {
  unsigned long long s = (unsigned long long)strtoull(v[1],0,0);
  int q = cq_theta(atoi(v[2]), 0.3);
  unsigned long long r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
