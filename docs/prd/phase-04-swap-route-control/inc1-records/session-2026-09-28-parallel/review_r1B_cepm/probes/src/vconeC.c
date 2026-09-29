#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int p = cq_theta(n, .4); int t = h(q, m); if (q > 5) p += t; return cq_measure(p) + cq_measure(q); }
