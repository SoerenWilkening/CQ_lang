#include <stdlib.h>
int main(int c, char **v) {
  long long s = (long long)strtoll(v[1],0,0);
  int q = cq_theta(atoi(v[2]), 0.3);
  long long r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
