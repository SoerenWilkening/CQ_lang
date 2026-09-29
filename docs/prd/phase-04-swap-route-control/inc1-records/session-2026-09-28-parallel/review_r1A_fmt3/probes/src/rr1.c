#include <stdlib.h>
/* r1A: register-register pin on a SURVIVING edge: does any -O1 pass (EarlyCSE edge equality?) rewrite t -> s in the arm? */
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  int t = cq_theta(m, .5); int s = cq_theta(n, .7); int r = 7;
  if (t == s) r = cq_theta(t, .9);
  return cq_measure(r) + cq_measure(s); }
