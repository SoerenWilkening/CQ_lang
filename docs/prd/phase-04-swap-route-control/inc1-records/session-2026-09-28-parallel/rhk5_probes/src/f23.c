/* f23 — a clone consumer INSIDE a loop of a rail minted OUTSIDE it (multiplicity) */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int acc = 0; for (int i = 0; i < m; i++) { int s = h(m, p); acc += cq_measure(s); } int u = p ^ q; if (u == 10) cq_phi(3.14159); q = cq_theta(q, .7); return acc + cq_measure(q); }
