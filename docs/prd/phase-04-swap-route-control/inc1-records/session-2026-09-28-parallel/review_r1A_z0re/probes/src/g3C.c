#include <stdlib.h>
/* runtime-seed prep inside a loop whose condition register is rotated each trip (G-13 probe: trailing non-diagonal gate) */
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int acc = 0;
  for (int i = 0; i < 3; i++) { int r = s + i; if (q2 > 3) r = cq_theta(s + i, .2); acc += cq_measure(r); }
  q2 = cq_theta(q2, .6);
  return acc + cq_measure(q2); }
