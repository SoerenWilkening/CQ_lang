#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = (m + 1); int r = t; if (m > 3) r = cq_theta(t, .2); int p = q; if (m > 4) p = cq_theta(q, .3); int b = cq_theta(q, .7); int w = p + 3; return cq_measure(r) + cq_measure(w) + cq_measure(b); }
