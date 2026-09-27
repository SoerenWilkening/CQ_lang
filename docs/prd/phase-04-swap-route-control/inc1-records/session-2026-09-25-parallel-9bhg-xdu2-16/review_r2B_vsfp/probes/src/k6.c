#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int r = h(p, m); int u = p + 1; q = cq_theta(q, .7); return r + cq_measure(u) + cq_measure(q); }
