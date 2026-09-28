/* k07 — r1B F-5 isolation: l1 WITHOUT the chain — does the per-trip clone result alone warn? */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, 0.5); int acc = 0; for (int i = 0; i < m; i++) acc += cq_measure(h(i, q)); q = cq_theta(q, 0.7); return acc + cq_measure(q); }
