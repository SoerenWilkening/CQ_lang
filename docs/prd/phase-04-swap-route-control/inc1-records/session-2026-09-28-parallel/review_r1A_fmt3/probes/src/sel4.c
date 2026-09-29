#include <stdlib.h>
/* r1A: the if/else-of-two-thetas spelling of sel1 (the fmt3 merge route with a REGISTER pin) */
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  int t = cq_theta(m, .5); int s = cq_theta(n, .7); int r;
  if (t == s) r = cq_theta(t, .9); else r = cq_theta(s, .9);
  return cq_measure(r); }
