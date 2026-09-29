#include <stdlib.h>
struct P { int a, b; }; struct P hs(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); struct P p = hs(q, n); int t = p.a + p.b; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q); }
