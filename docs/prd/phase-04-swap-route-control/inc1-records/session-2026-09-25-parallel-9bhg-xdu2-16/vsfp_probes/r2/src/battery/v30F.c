#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }
