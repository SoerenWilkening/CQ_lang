#include <stdlib.h>
/* r1A: register-register measure merge: if (t == s) m = cq_measure(t); else m = cq_measure(s); */
int main(int c, char **v) { int t = cq_theta(atoi(v[1]), .5); int s = cq_theta(atoi(v[2]), .7); int m;
  if (t == s) m = cq_measure(t); else m = cq_measure(s);
  int u = cq_theta(t, .9);
  return m + cq_measure(u); }
