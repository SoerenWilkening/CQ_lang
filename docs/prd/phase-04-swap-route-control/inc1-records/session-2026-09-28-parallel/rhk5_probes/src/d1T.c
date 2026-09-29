#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int r = m + 1; int u = p ^ q; int s = q + 1; int s2 = m + 3; if (u == 10) cq_phi(3.14159); q = cq_theta(q, .7); return r + s2 + cq_measure(s) + cq_measure(q); }
