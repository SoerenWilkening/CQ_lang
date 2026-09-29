#include <stdlib.h>
/* switch on a quantum scrutinee with runtime-seed prep arms */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int r = s;
  switch (q) { case 1: r = cq_theta(s, .2); break; case 3: r = cq_theta(s + 1, .7); break; default: break; }
  return cq_measure(r) + cq_measure(q); }
