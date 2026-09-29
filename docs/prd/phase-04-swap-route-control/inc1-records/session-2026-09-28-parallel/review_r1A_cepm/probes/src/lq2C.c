#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < n; i++) { int p = q + i; acc += h(p, i); } int q2 = cq_theta(n, .4); if (acc > 5) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q); }
