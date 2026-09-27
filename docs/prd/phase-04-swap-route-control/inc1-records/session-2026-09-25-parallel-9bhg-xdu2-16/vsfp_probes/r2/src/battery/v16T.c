#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); int t = p * 3 + m; int u = q + 6; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r) + cq_measure(p); }
