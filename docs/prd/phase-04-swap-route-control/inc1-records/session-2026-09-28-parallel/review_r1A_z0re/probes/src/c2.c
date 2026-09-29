#include <stdlib.h>
/* seed loaded from an array that holds quantum values (rail bank?) */
int main(int c, char **v) { int m = atoi(v[1]), k = atoi(v[2]); int a[2]; a[0] = cq_theta(m, .5); a[1] = cq_theta(k, .3);
  int q2 = cq_theta(7, .4); int s = a[k & 1]; int r = s; if (q2 > 3) r = cq_theta(s, .2);
  return cq_measure(r) + cq_measure(q2); }
