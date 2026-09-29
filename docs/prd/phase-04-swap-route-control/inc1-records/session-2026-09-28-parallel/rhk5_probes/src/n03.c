/* n03 — no control flow at all: the chain's consumer is a measured template (interior, not a kickback) */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); int w = u + 1; int ms = cq_measure(s) + cq_measure(w); q = cq_theta(q, .7); return ms + cq_measure(q); }
