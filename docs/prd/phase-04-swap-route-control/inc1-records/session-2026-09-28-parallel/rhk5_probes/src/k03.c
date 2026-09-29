/* k03 — Q+Q clone h(p, q2) after the Ry: reads the rotated register AND the chain rail */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q & 3; int u = p + q; if (u == 10) cq_phi(3.14159); int q2 = cq_theta(q, .7); int s = h(p, q2); return cq_measure(s) + cq_measure(q2); }
