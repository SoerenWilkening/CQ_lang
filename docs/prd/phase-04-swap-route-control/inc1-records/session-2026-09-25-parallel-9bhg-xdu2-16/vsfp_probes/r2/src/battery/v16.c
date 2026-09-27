#include <stdlib.h>
int h(int a, int b, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); int t = h(q, p, m); int u = q + 6; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r) + cq_measure(p); }
