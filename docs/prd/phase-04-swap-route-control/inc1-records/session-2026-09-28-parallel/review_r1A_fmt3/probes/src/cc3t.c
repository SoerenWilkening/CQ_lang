#include <stdlib.h>
/* r1A: cc3's TERNARY twin (the select-angle spelling old -O1 produced from the if/else) */
int main(int c, char **v) { int n = atoi(v[2]); int p = cq_theta(atoi(v[1]), .2);
  for (int i = 0; i < n; i++) p = cq_theta(p, (i & 1) ? .9 : .3);
  return cq_measure(p); }
