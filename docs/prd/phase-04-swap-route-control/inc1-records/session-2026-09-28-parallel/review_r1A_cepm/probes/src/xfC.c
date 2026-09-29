#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int F(int m, int n) { int q = cq_theta(m, .5); int t = h(q, n); return t + 100 * cq_measure(q); }
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int t = F(m, n); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2); }
