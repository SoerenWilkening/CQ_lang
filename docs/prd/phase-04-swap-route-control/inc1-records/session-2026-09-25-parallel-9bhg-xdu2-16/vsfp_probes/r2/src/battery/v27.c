#include <stdlib.h>
int h(int a, int k); int h1(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h1(q, m); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? t : 7; int u = h(p, m); b = cq_theta(b, .7); return u + cq_measure(b) + cq_measure(q); }
