#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .4); int s = h(q, m); int r = s; if (q2 > 5) r = cq_theta(s, .3); return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
