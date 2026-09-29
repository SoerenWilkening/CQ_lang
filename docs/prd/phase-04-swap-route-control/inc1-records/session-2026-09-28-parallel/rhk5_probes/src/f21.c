/* f21 — ROLLED loop, register outside: chain + clone call + kickback per trip */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int acc = 0; for (int i = 0; i < m; i++) { int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi(3.14159); acc += cq_measure(s); } q = cq_theta(q, .7); return acc + cq_measure(q); }
