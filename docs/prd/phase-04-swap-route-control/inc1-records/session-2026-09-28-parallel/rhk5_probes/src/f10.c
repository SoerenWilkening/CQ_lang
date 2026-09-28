/* f10 — chain consumed TWICE (two kickbacks), call between them */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi(3.14159); int s = h(m, q); if (u > 12) cq_phi(0.25); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q); }
