#include <stdlib.h>
int h(int a, int k); int g2(int a, int b);
__attribute__((noinline)) int F(int m, int n) { int q = cq_theta(m, .5); int t = h(q, n); return t + 100 * cq_measure(q); }
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int t = F(m, n); int q2 = cq_theta(n, .4); int u = g2(t, q2); return cq_measure(u) + cq_measure(q2); }
