#include <stdlib.h>
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int acc = 0;
  { int r = s + 0; if (q2 > 3) r = cq_theta(s + 0, .2); acc += cq_measure(r); }
  { int r = s + 1; if (q2 > 3) r = cq_theta(s + 1, .2); acc += cq_measure(r); }
  { int r = s + 2; if (q2 > 3) r = cq_theta(s + 2, .2); acc += cq_measure(r); }
  q2 = cq_theta(q2, .6);
  return acc + cq_measure(q2); }
