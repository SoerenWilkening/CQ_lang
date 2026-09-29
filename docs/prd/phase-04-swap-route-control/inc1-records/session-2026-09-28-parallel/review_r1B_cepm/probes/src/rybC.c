#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .4); int q3 = cq_theta(m + 2, .7); if (q > 5) q2 = cq_theta(q2, h(q3, m) * 0.1); return cq_measure(q2) + cq_measure(q) + cq_measure(q3); }
