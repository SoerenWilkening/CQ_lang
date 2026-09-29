#include <stdlib.h>
int h(int a, int k); int ext_f(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int i; for (i = 0; i < 4; i++) { if (y == i) break; } int t = h(q, i); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q); }
