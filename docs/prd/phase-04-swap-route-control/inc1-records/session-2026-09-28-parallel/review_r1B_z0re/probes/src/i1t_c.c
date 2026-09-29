#include <stdlib.h>
#include <stdio.h>
int main(int c, char **v) {
  int x = atoi(v[1]);
  _Bool s = x & 1;
  if (x > 100) puts("big");
  int q = cq_theta(atoi(v[2]), 0.3);
  _Bool r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return cq_measure(r) + cq_measure(q) + s;
}
