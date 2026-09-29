#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4); int t = h(q, n); int r = t; if (q2 > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
